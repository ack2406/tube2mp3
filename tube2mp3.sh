#!/bin/bash
#
# Author            : Marcin Połajdowicz
# Created On        : 07.05.2021
# Last modified By  : Marcin Połajdowicz
# Last modified On  : 11.05.2021
# Version           : 1.0
#
# Description       : Script used for downloading and converting music from YouTube to mp3
#
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact
# the Free Software Foundation for copy)
 
 
 
# some constants
scriptTitle="$0"
scriptVersion="1.0"
 
# function for -h
help() {
    echo "Syntax: $scriptTitle [-h|v]"
    echo "options:"
    echo "h     Print this Help."
    echo "v     Print script version and exit."
 
}
 
# function for -v
version() {
    echo "$scriptTitle version: $scriptVersion"
}
 
# show this windows when user will Cancel button
showCancelWindow() {
    local cause=$1
    dialog --stdout --title $scriptTitle --infobox "Script stopped.\n$cause." 5 45
}
 
# window for displaying inputbox asking for url
showAddressWindow()  {
    local lAskAddress="Enter Youtube address:"
    address=`dialog --stdout --title "$scriptTitle" --inputbox "$lAskAddress" 10 50`
    regex="v=(.*)"
    # check if given url is correct 
    if ! [[ $address =~ $regex ]]; then
        showCancelWindow "URL is not right"
        exit 
    fi
    if [ $? -ne 0 ]; then # if clicked Cancel button
        showCancelWindow "Cancelled at address"
        exit
    fi
}
 
# window for selecting destination directory of mp3 file
showDirectoryWindow() {
    local lAskDirectory="Enter the destination directory path:"
    destDirectory=`dialog --stdout --title "$scriptTitle $lAskDirectory" --dselect $PWD 10 50`
    if [ $? -ne 0 ]; then
        showCancelWindow "Cancelled at directory"
        exit
    fi
}
 
# window for choosing bitrate for mp3 file
showBitrateWindow() {
    bitrate=`dialog --stdout --title "$scriptTitle"\
    --radiolist "Select Bitrate" 15 60 3 128 "128 bitrate" off 192 "192 bitrate" off 256 "256 bitrate" on`
    if [ $? -ne 0 ]; then
        showCancelWindow "Cancelled at bitrate"
        exit
    fi
}
 
# window for choosing what to do with video
showVideoWindow() {
    videoSave=`dialog --stdout --title "$scriptTitle"\
    --radiolist "Keep the video?" 15 60 2 0 "Yes" off 1 "No" on`
    if [ $? -ne 0 ]; then
        showCancelWindow "Cancelled at keeping the video"
        exit
    fi
}
 
# main function for downloading, converting and encoding
getFile() {
    # get url parameter
    address=${1}
 
    # get youtube file title
    dialog --stdout --title $scriptTitle --infobox "Getting youtube file title..." 5 45
    local lTitle=`youtube-dl --default-search "ytsearch" --get-title $address`
 
    # download file
    dialog --stdout --title $scriptTitle --infobox "Downloading mp4..." 5 45
    youtube-dl --default-search "ytsearch" -q -o "$lTitle" -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]' $address
 
    # convert to wav
    dialog --stdout --title $scriptTitle --infobox "Converting to wav..." 5 45
    ffmpeg -hide_banner -loglevel error -i "${lTitle}".mp4 "/tmp/$lTitle.wav"
 
    # encoder from wav to mp3
    dialog --stdout --title $scriptTitle --infobox "Encoding to mp3..." 5 45
    lame --quiet "/tmp/$lTitle.wav" "$destDirectory/${lTitle}.mp3" -b $bitrate
 
    # remove temporary wav file
    rm "/tmp/$lTitle.wav"
 
    # remove mp4 file if user chose to
    if [ $videoSave -ne 0 ]; then
        rm "${lTitle}".mp4
    fi
 
    # display final window about succesful finish of script!
    dialog --stdout --title $scriptTitle --infobox "Your mp3 file is ready." 5 45
 
 
}
 
 
# checking if user gave parameters to script
while getopts ":hv" opt; do
    case ${opt} in
        h ) help
            exit;;
        v ) version
            exit;;
        * ) echo "Invalid option" 
            exit;;
    esac
done
 
# here is the start of the script displaying windows in order
 
showAddressWindow
showDirectoryWindow
showBitrateWindow
showVideoWindow
 
if [[ $address =~ $regex ]]; then
    getFile ${BASH_REMATCH[1]}
fi