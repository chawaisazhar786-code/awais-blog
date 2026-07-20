#!/bin/bash

set -e

git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

export PATH="$HOME/flutter/bin:$PATH"

flutter doctor

flutter pub get

flutter build web