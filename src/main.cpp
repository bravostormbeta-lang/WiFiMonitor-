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

    engine.loadFromModule("WiFiMonitorUI", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}