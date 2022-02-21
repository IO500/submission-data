use std::env;
use std::ffi::{CStr, CString};
use std::fs;
use std::os::raw::c_char;
use std::sync::mpsc;
use std::thread;
use std::time::SystemTime;

use bpfs::bpfs_sdk::*;
use export::pfind::{PfindArgs, PfindResult, PfindSize, PfindTime, PfindTimeType, Relation};
use frontend::api::*;
use frontend::dirent::*;
use frontend::init::bpfs_frontend_init;

fn get_size(mut size_str: String) -> i64 {
    size_str.split_off(size_str.len() - 1);
    let s = size_str.parse::<u64>();
    let size = match s {
        Ok(size) => size as i64,
        Err(e) => {
            println!("get size parameter failed.{:?}", e);
            -1
        }
    };

    size
}

fn get_timestamp_file_mtime(file_name: &String) -> u64 {
    let meta_data = match fs::metadata(file_name) {
        Ok(meta_data) => meta_data,
        Err(error) => {
            println!("get ts file {} meta failed.", file_name);
            return 0;
        }
    };

    let time = match meta_data.modified() {
        Ok(time) => time,
        Err(error) => {
            println!("get modified time of ts file {} failed.", file_name);
            return 0;
        }
    };

    match time.duration_since(SystemTime::UNIX_EPOCH) {
        Ok(mtime) => mtime.as_nanos() as u64,
        Err(error) => {
            println!("cal ts create file {} failed.", file_name);
            return 0;
        }
    }
}

fn transfer_cstring(param: String) -> Option<*const c_char> {
    let r = CString::new(param);
    let c = match r {
        Ok(c) => c,
        Err(e) => {
            println!("user name failed.{:?}", e);
            return None;
        }
    };
    let raw = c.into_raw();
    let c = raw as *const c_char;

    return Some(c);
}

fn list_dirs(dir: &String, dirs: &mut Vec<String>, fsid: &String) -> i32 {
    let buf = &mut [0u8; 32767];
    let dirbuf = buf.as_mut_ptr();

    let api = FrontEndApiImpl::new();
    let fd = api.opendir(fsid.to_string(), &dir);
    if fd <= 0 {
        println!("opendir {} failed.", &dir);
        return -1;
    }

    while true {
        let ret = api.getdents(fd, dirbuf, 32767);
        if ret < 0 {
            println!("getdents {} failed.", dir);
        } else if ret == 0 {
            break;
        }

        let mut offset = 0;
        while offset < ret {
            unsafe {
                let dent = buf[offset as usize..].as_mut_ptr() as *mut LinuxDirent;
                let name = CStr::from_ptr((*dent).d_name.as_mut_ptr() as *mut i8)
                    .to_string_lossy()
                    .into_owned();

                offset += (*dent).d_reclen as i32;
                if name == "mdtest-hard" || name == "mdtest-easy" || name.contains("test-dir") {
                    list_dirs(&format!("{}/{}", dir, name), dirs, &fsid);
                } else {
                    dirs.push(format!("{}/{}", dir, name));
                }
            }
        }
    }

    return 0;
}

fn init_bpfs() -> i32 {
    let user = transfer_cstring("test".to_string());
    let user_name = match user {
        None => {
            return -1;
        }
        Some(user_name) => user_name,
    };

    let passwd = transfer_cstring("123456".to_string());
    let password = match passwd {
        None => {
            return -1;
        }
        Some(password) => password,
    };

    let fs = transfer_cstring("bpfs".to_string());
    let fs_name = match fs {
        None => {
            return -1;
        }
        Some(fs_name) => fs_name,
    };

    let bpfs = transfer_cstring("/home/bpfs/BPFS.json".to_string());
    let bpfs_config = match bpfs {
        None => {
            return -1;
        }
        Some(bpfs_config) => bpfs_config,
    };

    unsafe {
        bpfs_frontend_init(false);
    };

    0
}

fn open_all_dirs(dirs: &mut Vec<String>, fds: &mut Vec<i32>, fsid: &String) -> i32 {
    let api = FrontEndApiImpl::new();
    for i in 0..dirs.len() {
        let dirs = dirs.clone();
        let fd = api.opendir(fsid.to_string(), &dirs[i].to_string());
        if fd <= 0 {
            println!("opendir {} failed.", &dirs[i].to_string());
            return -1;
        }

        fds.push(fd);
    }

    0
}

fn pfind_serial(
    find_args: PfindArgs,
    dirs: &Vec<String>,
    fds: &Vec<i32>,
    total_res: &mut PfindResult,
) -> i32 {
    for i in 0..fds.len() {
        let dirs = dirs.clone();
        let find_args = find_args.clone();
        let api = FrontEndApiImpl::new();

        let mut res = PfindResult {
            found: 0,
            total: 0,
            paths: None,
        };

        let ret = api.pfind(fds[i], find_args, &mut res);
        if ret < 0 {
            println!("pfind error");
            return -1;
        }

        total_res.found += &res.found;
        total_res.total += &res.total;
    }

    0
}

fn pfind_parallel(
    find_args: PfindArgs,
    dirs: &Vec<String>,
    fds: &Vec<i32>,
    total_res: &mut PfindResult,
) -> i32 {
    let thread_num = 8;
    let mut from = 0;
    let mut end = thread_num;
    if fds.len() > thread_num {
        end = thread_num;
    } else {
        end = fds.len();
    }

    loop {
        let (tx, rx) = mpsc::channel();
        for i in from..end {
            let dirs = dirs.clone();
            let find_args = find_args.clone();
            let api = FrontEndApiImpl::new();
            let tx = mpsc::Sender::clone(&tx);
            let fd = fds[i];

            thread::spawn(move || {
                let mut res = PfindResult {
                    found: 0,
                    total: 0,
                    paths: None,
                };

                let ret = api.pfind(fd, find_args, &mut res);
                if ret < 0 {
                    println!("pfind error");
                    return -1;
                }

                let r = tx.send(res);
                let res = match r {
                    Ok(res) => res,
                    Err(e) => {
                        println!("tx send failed.{:?}", e);
                        return -1;
                    }
                };
                drop(tx);

                0
            });
        }

        let r = tx.send(PfindResult {
            found: 0,
            total: 0,
            paths: None,
        });
        let res = match r {
            Ok(res) => res,
            Err(e) => {
                println!("tx send failed.{:?}", e);
                return -1;
            }
        };
        drop(tx);

        for recv in rx {
            total_res.found += recv.found;
            total_res.total += recv.total;
        }

        if end >= fds.len() {
            return 0;
        }

        from += thread_num;
        end += thread_num;
        if end > fds.len() {
            end = fds.len();
        }
    }

    0
}

fn bpfs_pfind(args: Vec<String>) -> i32 {
    if args.len() < 8 {
        println!("pfind access 8 params but got {} params.", args.len());
        println!("Usage: pfind DATA_DIR -newer TIMESTAMP_FILE -size SIZEc -name NAME_REGEX");
        return -1;
    }

    let size = get_size(args[5].clone());
    if size < 0 {
        return -1;
    }

    let timestamp_mtime = get_timestamp_file_mtime(&args[3]);

    let ctime = PfindTime {
        rtype: PfindTimeType::Ctime,
        value: timestamp_mtime,
        relation: Relation::GreatOrEqual,
    };

    let fsize = PfindSize {
        value: size as u64,
        relation: Relation::Equal,
    };

    let find_args = PfindArgs {
        count_only: true,
        time: Some(ctime),
        size: Some(fsize),
        regx: Some(args[7].clone()),
    };

    let ret = init_bpfs();
    if ret < 0 {
        println!("init bpfs failed");
        return -1;
    }

    let mut timestamp_file = args[1].clone();
    let mut dir: String = String::new();
    let mut fsid: String = String::new();

    if args.len() == 8 {
        dir = timestamp_file.split_off("/bpfs/mnt/bpfs1".len());
        fsid = "bpfs1".to_string();
    } else {
        dir = timestamp_file.split_off(args[8].len());
        fsid = args[9].clone();
    }

    let mut dirs: Vec<String> = Vec::new();
    let ret = list_dirs(&dir, &mut dirs, &fsid);
    if ret < 0 {
        return -1;
    }

    let mut fds: Vec<i32> = Vec::new();
    let mut ret = open_all_dirs(&mut dirs, &mut fds, &fsid);
    if ret < 0 {
        return -1;
    }

    let mut total_res = PfindResult {
        found: 0,
        total: 0,
        paths: None,
    };

    if args.len() == 11 {
        // 调试用
        if "seq" == args[10] {
            ret = pfind_serial(find_args.clone(), &dirs, &fds, &mut total_res);
        } else if "para" == args[10] {
            ret = pfind_parallel(find_args.clone(), &dirs, &fds, &mut total_res);
        } else {
            println!("run mode failed.");
            return -1;
        }
    } else {
        ret = pfind_parallel(find_args.clone(), &dirs, &fds, &mut total_res);
    }

    if ret < 0 {
        return -1;
    }

    println!("MATCHED {}/{}", total_res.found, total_res.total);

    return 0;
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let ret = bpfs_pfind(args);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_size() {
        let size = get_size("10c".to_string());
        assert_eq!(size, 10);
    }

    #[test]
    fn test_get_timestamp_file_mtime() {
        let mtime = get_timestamp_file_mtime(&"/etc/bashrc".to_string());
        if mtime == 0 {
            panic!("Get /etc/bashrc mtime failed");
        }
    }
}
