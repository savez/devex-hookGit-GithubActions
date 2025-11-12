#!/bin/bash

echo ""
echo "🤖 Generate SWAGGER documentation"
echo "================================"
echo ""

node ./generate-swagger.js # si può usare anche make generate-swagger
git add .
git commit -m "autocommit: added swagger"
exit 0