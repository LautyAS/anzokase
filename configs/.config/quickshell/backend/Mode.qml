pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: modeObj
    property string mode: "dark"

    function load() {
        var home = Quickshell.env("HOME")
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + home + "/.config/quickshell/colors/.current_mode?t=" + Date.now(), false)
        xhr.send()

        if (xhr.status === 200) {
            mode = xhr.responseText.trim()
            console.log("Mode loaded:", mode)
        }
    }

    Component.onCompleted: load()
}
