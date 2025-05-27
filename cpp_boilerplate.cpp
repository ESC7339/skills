#include <iostream>
#include <fstream>
#include <cstdlib>
#include <csignal>
#include <filesystem>
#include <string>
#include <vector>
#include <memory>

namespace fs = std::filesystem;

static fs::path inputIso;
static fs::path outputImage;
static fs::path workDir;
static fs::path isoMount;
static fs::path isoRoot;
static fs::path chrootDir;
static bool workDirProvided = false;

void log(const std::string& msg) {
    std::cout << "[INFO] " << msg << std::endl;
}

[[noreturn]] void die(const std::string& msg) {
    std::cerr << "[ERROR] " << msg << std::endl;
    std::exit(EXIT_FAILURE);
}

void run(const std::string& cmd) {
    log("Executing: " + cmd);
    int ret = std::system(cmd.c_str());
    if (ret != 0) {
        die("Command failed: " + cmd);
    }
}

void cleanup() {
    log("Running cleanup...");
    if (fs::exists(isoMount) && fs::is_directory(isoMount)) {
        std::string umountCmd = "umount -lf " + isoMount.string();
        std::system(umountCmd.c_str());
    }
    if (!workDirProvided && fs::exists(workDir)) {
        log("Removing temporary workdir " + workDir.string());
        std::error_code ec;
        fs::remove_all(workDir, ec);
    }
    log("Cleanup complete.");
}

void handleSignal(int sig) {
    std::exit(1);
}

void checkRoot() {
    if (geteuid() != 0) {
        die("This script must be run as root.");
    }
}

void ensureDirectory(const fs::path& path) {
    std::error_code ec;
    if (!fs::exists(path)) {
        fs::create_directories(path, ec);
        if (ec) {
            die("Failed to create directory: " + path.string());
        }
    }
}

int main(int argc, char* argv[]) {
    std::atexit(cleanup);
    std::signal(SIGINT, handleSignal);
    std::signal(SIGTERM, handleSignal);
    std::signal(SIGHUP, handleSignal);

    checkRoot();

    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " -i <input.iso> [-o <output.img>] [-w <workdir>]" << std::endl;
        return EXIT_FAILURE;
    }

    std::string isoArg, outArg, workArg;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if ((arg == "-i" || arg == "--input") && i + 1 < argc) {
            isoArg = argv[++i];
        } else if ((arg == "-o" || arg == "--output") && i + 1 < argc) {
            outArg = argv[++i];
        } else if ((arg == "-w" || arg == "--workdir") && i + 1 < argc) {
            workArg = argv[++i];
        }
    }

    if (isoArg.empty()) {
        die("Input ISO is required.");
    }

    inputIso = fs::absolute(isoArg);
    if (!fs::exists(inputIso)) {
        die("Input ISO not found: " + inputIso.string());
    }

    if (!outArg.empty()) {
        outputImage = fs::absolute(outArg);
    } else {
        outputImage = inputIso.parent_path() / (inputIso.stem().string() + "-custom.img");
    }

    if (outputImage.extension() != ".img") {
        die("Output must end in .img");
    }

    if (!workArg.empty()) {
        workDir = fs::absolute(workArg);
        workDirProvided = true;
    } else {
        workDir = fs::temp_directory_path() / fs::path("sudobuild-" + std::to_string(std::rand()));
    }

    isoMount = workDir / "iso-mount";
    isoRoot = workDir / "iso-root";
    chrootDir = workDir / "chroot";

    ensureDirectory(isoMount);
    ensureDirectory(isoRoot);
    ensureDirectory(chrootDir);

    log("Input ISO: " + inputIso.string());
    log("Output: " + outputImage.string());
    log("Workdir: " + workDir.string());

    log("Mounting ISO...");
    run("mount -o loop " + inputIso.string() + " " + isoMount.string());

    log("Copying ISO contents...");
    run("cp -a " + isoMount.string() + "/. " + isoRoot.string());

    log("Preparing chroot patching (placeholder)...");
    // unsquashfs, patch chroot, etc.

    log("Writing final image (placeholder) to: " + outputImage.string());
    // genisoimage or mkisofs logic

    log("Script completed successfully.");
    return EXIT_SUCCESS;
}
