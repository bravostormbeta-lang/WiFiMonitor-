import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    width: 800
    height: 600

    visible: true

    title: "WiFi Monitor"

    Column {
        anchors.centerIn: parent

        spacing: 12

        Text {
            text: "WiFi Monitor"
            font.pixelSize: 32
        }

        Text {
            text: "Network: " + wifiController.ssid
            font.pixelSize: 22
        }

        Text {
            text: "BSSID: " + wifiController.bssid
            font.pixelSize: 22
        }

        Text {
            text: "RSSI: " + wifiController.signalStrength + " dBm"
            font.pixelSize: 22
        }

        Text {
            text: "Noise: " + wifiController.noise + " dBm"
            font.pixelSize: 22
        }

        Text {
            text: "Transmit Rate: " + wifiController.transmitRate + " Mbps"
            font.pixelSize: 22
        }

        Text {
            text: "Channel: " + wifiController.channel
            font.pixelSize: 22
        }

        Text {
            text: "Band: " + wifiController.band
            font.pixelSize: 22
        }

        Text {
            text: "PHY: " + wifiController.phyMode
            font.pixelSize: 22
        }

        Text {
            text: "Channel Width: " + wifiController.channelWidth
            font.pixelSize: 22
        }
    }
}