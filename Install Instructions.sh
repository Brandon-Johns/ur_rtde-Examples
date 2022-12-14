exit 1 # In case someone calls this as a script

# Written by:		Brandon Johns
# Version created:	2022-11-21
# Last edited:		2022-11-21

# Purpose:
#   Install C++ library ur_rtde: https://sdurobotics.gitlab.io/ur_rtde/
#   The installation is contained into a local directory, to not mess with the rest of the computer

# VERSION:
#   This install is not compatible with the Vicon DataStreamSDK (for the motion capture)
#   Instead, it installs with the new C++11 String ABI, which is more compatible with other modern C++ libraries
#   Refer to: https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html

# TO USE:
#   Do not run this as a script
#   Follow the instructions in order and copy paste the relevant commands into the bash shell


####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
# Installation
####################################################################################################################################
# Install basic utils & dependencies
#################################
sudo apt-get update
sudo apt install git -y

### Dependancies of boost
sudo apt-get install python-dev autotools-dev libicu-dev libbz2-dev libopenblas-dev -y

# Also install a new version of CMake from
# https://cmake.org/download/
# The apt-get version is ancient
# NOTE: I've already done this for the UR5 control computer


##################################################################
# Setup directory to install into
#################################
### Install dir
### Change this directory to the directory you wish to install ur_rtde into
bjLibDir='/home/acrv/ur_rtde/local_lib'

# These are required in the installation process
mkdir ${bjLibDir}/src


##################################################################
# Install Boost
#	https://stackoverflow.com/a/41272796
#################################
cd ${bjLibDir}/src

### Download
wget "https://sourceforge.net/projects/boost/files/boost/1.80.0/boost_1_80_0.tar.gz"
tar xzvf boost_1_80_0.tar.gz


### Pre-install
cd boost_1_80_0/
./bootstrap.sh --prefix=$bjLibDir --includedir=include --libdir=lib

n=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $NF}'`
echo "Num CPU Cores: $n"

### Install 
#   Check installation options with
#	    ./b2 --help
#   Check libraries being build with the flag --show-libraries
#   Then remove the --show-libraries flag and run again to perform the install
sudo ./b2 install -j$n -a --with=all --layout=tagged threading=multi --prefix=$bjLibDir --show-libraries

##################################################################
# Install ur_rtde
#################################
cd ${bjLibDir}/src

### Download
git clone https://gitlab.com/sdurobotics/ur_rtde.git
cd ur_rtde
git checkout tags/v1.5.4
### NOTE: Skipping python bindings => no need to run
#   git submodule update --init --recursive

### Build
#   DESTDIR doesn't seem to do anything but oh well
mkdir build
cd build
cmake -DPYTHON_BINDINGS:BOOL=OFF -DCMAKE_INSTALL_PREFIX=$bjLibDir -DCMAKE_PREFIX_PATH=$bjLibDir DESTDIR=$bjLibDir ..
make

### Install
sudo make install
### ACTION: (To fix paths so it works from my custom install dir)
#   Edit: ${bjLibDir}/lib/cmake/ur_rtde/ur_rtdeBuildConfig.cmake
#       Change line 3
#           FROM:   set(RTDE_BOOST_LIBRARY_DIR )
#           TP:     set(RTDE_BOOST_LIBRARY_DIR /home/acrv/ur_rtde/local_lib/lib )
#   Edit: ${bjLibDir}/lib/cmake/ur_rtde/ur_rtdeConfig.cmake
#       Add lines just before last endif() in the file
#           # BJ:START Added
#           else()
#             find_package(Boost REQUIRED COMPONENTS system thread PATHS "/home/acrv/ur_rtde/local_lib/lib/cmake/Boost-1.80.0")
#           # BJ:END Added
#           endif() # BJ: This is the last line in the file


##################################################################
# Finishing up
#################################
cd ${bjLibDir}

# Give everything full permissions & set user to self
#   Check current permissions & owner/group with: ls -ld
#   UR5 control computer is "arcv:arcv"
sudo find include -exec chown acrv:acrv {} \;
sudo find lib -exec chown acrv:acrv {} \;


##################################################################
# Install Armadillo (Not a local install)
#################################
### ACTION:
#	Download latest stable version from: http://arma.sourceforge.net/download.html
#	Unzip
#	cd into unzipped dir
cmake . -DCMAKE_INSTALL_PREFIX:PATH=/usr/local
sudo make install


####################################################################################################################################
####################################################################################################################################
####################################################################################################################################
# Uninstalling / Resetting between subsequent compilations
####################################################################################################################################
# Boost
#################################
### Uninstall
sudo rm -rf ${bjLibDir}/include/boost # Dir
sudo rm -rf ${bjLibDir}/lib/libboost_* # Total 95 files starting with "libboost_"
sudo rm -rf ${bjLibDir}/lib/cmake/Boost* # Many dirs
sudo rm -rf ${bjLibDir}/lib/cmake/boost_* # Many dirs

### Reset before recompiling with b2
cd ${bjLibDir}/src/boost_1_80_0/
sudo ./b2 --clean
### ACTION:
#	Also follow uninstall instructions

### Reset completely
### ACTION:
#	Nuke boost src dir from orbit
#	Also follow uninstall instructions


##################################################################
# ur_rtde
#################################
### Uninstall
rm -rf ${bjLibDir}/include/urcl # Dir
rm -rf ${bjLibDir}/include/ur_rtde # Dir
rm -rf ${bjLibDir}/lib/librtde.so* # Total 3 files
rm -rf ${bjLibDir}/lib/cmake/ur_rtde # Dir

### Reset before recompiling
cd ${bjLibDir}/src/ur_rtde
rm -rf build
mkdir build
cd build
### ACTION:
#	Also follow uninstall instructions


##################################################################
# Armadillo
#################################
### To uninstall
sudo rm -rf /usr/local/include/armadillo_bits # Dir
sudo rm -rf /usr/local/include/armadillo # 1 file
sudo rm -rf /usr/local/lib/libarmadillo.so* # Total 3 files
sudo rm -rf /usr/local/share/Armadillo # Dir
sudo rm -rf /usr/local/lib/pkgconfig/armadillo.pc # 1 file

### To reset before recompiling
rm CMakeCache.txt



