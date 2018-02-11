#! /bin/bash
#
# afx

VBR="1500k" 
FPS="30" 
#QUAL="medium"
QUAL="veryfast"
YOUTUBE_URL="rtmp://a.rtmp.youtube.com/live2" 
KEY="..."

WINNAME="Minecraft 1.12.2"

#####################
offset_x=`xwininfo -name "$WINNAME" | grep geometry | cut -d '+' -f2`
offset_y=`xwininfo -name "$WINNAME" | grep geometry | cut -d '+' -f3`
width=`xwininfo -name "$WINNAME" | grep Width | cut -d ':' -f2 | tail -c +2 | head -c -1`
height=`xwininfo -name "$WINNAME" | grep Height | cut -d ':' -f2 | tail -c +2 | head -c -1`

echo "x11 to youtube capture"
echo "-=-=-=-=-=-=-=-=-=-=-="
echo $WINNAME resolution: $width x $height
echo $WINNAME X offset: $offset_x
echo $WINNAME Y offset: $offset_y
echo " "
echo "Ready?"
read

ffmpeg  \
	-video_size "$width"x"$height" -f x11grab -s "$width"x"$height" -i :0.0+"$offset_x","$offset_y" \
	-f pulse -ac 2 -i default \
	-vcodec libx264 -pix_fmt yuv420p -preset $QUAL -r $FPS -g $(($FPS * 2)) -b:v $VBR \
	-acodec libmp3lame -ar 44100 -threads 6 -qscale 3 -b:a 712000 -bufsize 512k \
	test.mp4
# 	-f "$YOUTUBE_URL/$KEY"

