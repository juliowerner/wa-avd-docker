sleep 15 && adb shell pm list packages | grep whatsapp &> /dev/null
if [ $? == 0 ]; then
    echo 'WhatsApp already installed'
else
    echo 'Installing WhatsApp'
    adb install /home/avd/whatsapp.apk
fi
