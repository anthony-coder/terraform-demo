#!/bin/bash
echo '<html><body>HEALTHY!</body></html>' > health.html

echo '<html><body>Hello, Terraform!</body></html>' > custom.html

# Start the web server
python3 -m http.server 8080 &