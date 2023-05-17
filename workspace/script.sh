#!/bin/bash

echo "Which script do you want to run?"
echo "1. Initialize Environment"
echo "2. Clean Environment"
echo "3. Execute Kitchen"
read choice

case $choice in
  1)
    sh docker-scripts/initialize.sh
    ;;
  2)
    sh docker-scripts/dockerclean.sh
    ;;
  3)
    sh docker-scripts/kitchenc.sh
    ;;
  *)
    echo "Invalid choice."
    ;;
esac
