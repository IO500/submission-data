// #/home/io500/io500/bin/pfind
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <regex>
#include <fstream>
using namespace std;


void
writeToFile(const std::string& fileName, const std::string& data) {
    std::ofstream outFile(fileName, std::ios::out | std::ios::app);
    if(outFile.is_open()) {
        outFile << data << std::endl;
        outFile.close();
    } else {
        std::cerr << "Error: Failed to open file for writing: " << fileName
                  << std::endl;
    }
}

// void extractLongs(const std::string& str, long& num1, long& num2)
// {
//     int count = std::sscanf(str.c_str(), "MATCHED %ld/%ld", &num1, &num2);
//     if (count != 2)
//     {
//         std::cerr << "Invalid input string: " << str << std::endl;
//     }
// }

std::string
execute_command(const std::string& command) {
    std::string output;
    char buffer[128];

    // Open the command for reading
    FILE* pipe = popen(command.c_str(), "r");
    if(!pipe)
        throw std::runtime_error("Failed to open pipe");

    // Read command output into a string
    while(fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        output += buffer;
    }

    // Close the pipe and get the exit status
    auto status = pclose(pipe);
    if(status == -1)
        throw std::runtime_error("Failed to close pipe");

    // Check if the command exited with an error
    // if(WEXITSTATUS(status) != 0) {
    //     throw std::runtime_error("Command exited with error");
    // }

    return output;
}

void
test_io500pfind(int argc, char* argv[]) {
    string pfind_command = "/home/io500/io500/bin/pfind ";
    for(int i = 1; i < argc; i++) {
        pfind_command += argv[i];
        pfind_command += " ";
    }
    // cout << endl << pfind_command << endl ;
    string output = execute_command(pfind_command);
    std::string fileName =
            "/home/io500/GKFS/gekkofs/pfind/test_correct/log.txt";
    writeToFile(fileName, output);
}

long get_time(char* filename){
    struct stat file_stat;

    if (stat(filename, &file_stat) != 0) {
        std::cout << "File creation time: " <<  static_cast<long>(file_stat.st_ctime) << endl;
        return 0;
    }    
    return static_cast<long>(file_stat.st_ctime) ;
}

int
main(int argc, char* argv[]) {

    long ltime = get_time(argv[3]);
    string stime = std::to_string(ltime);
    const char* ctimestr = stime.c_str();

    unsigned int type = 10086;
    int match = open(ctimestr, type);
    type += 1;
    int total = open(ctimestr, type);
     printf("MATCHED %d/%d\n", match, total);
    return 0;
}
