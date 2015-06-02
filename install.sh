#!/bin/bash

echo "Install jars in local maven repository"
mkdir -p ~/.m2/repository
cp -r m2repo/ ~/.m2/repository