#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "ui/WiFiMonitorController.h"
#include "platform/macos/WiFiMacOS.h"


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;


    // ============================================================
    // Platform implementation
    //
    // The application composition root owns the concrete
    // platform implementation.
    // ============================================================

    WiFiMacOS platform;


    // ============================================================
    // Controller
    //
    // The controller receives the platform through the
    // IWiFiPlatform abstraction.
    // ============================================================

    WiFiMonitorController controller(
        &platform
    );


    engine.rootContext()->setContextProperty(
        "wifiController",
        &controller
    );


    const QUrl url(
        QStringLiteral("qrc:/qt/qml/WiFiMonitor/qml/Main.qml")
    );


    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );


    engine.load(url);


    return app.exec();
}