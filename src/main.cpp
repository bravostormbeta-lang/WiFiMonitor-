#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "ui/WiFiMonitorController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    WiFiMonitorController controller;

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