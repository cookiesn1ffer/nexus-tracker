#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <linux/limits.h>
#include <unistd.h>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>

#include "my_application.h"

int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
