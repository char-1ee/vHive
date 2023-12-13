#!/bin/bash

# Define paths
PERF_DATA_PATH="./perf.data"
PERF_REPORT_TXT_PATH="./perf-report.txt"

# Start perf in the background to monitor page faults
sudo perf record -e minor-faults -e major-faults -o $PERF_DATA_PATH -p $$ &
PERF_PID=$!

# Check if perf started correctly
echo "Perf started with PID: $PERF_PID"

# Replace this with the command to run your tests
./scripts/cloudlab/setup_node.sh
go build -race -v -a ./...
make test 2>&1 | tee ./output

# Check if PERF_PID is still valid
if ps -p $PERF_PID > /dev/null
then
   echo "Stopping perf with PID $PERF_PID"
   # Terminate perf record
   sudo kill -INT $PERF_PID

   # Wait for perf record to finish processing
   wait $PERF_PID
   sudo chown $(whoami) $PERF_DATA_PATH
else
   echo "Perf process not found"
fi

# Generate the perf report and save to a file
sudo perf report -i $PERF_DATA_PATH --stdio > $PERF_REPORT_TXT_PATH

# Cleanup
./scripts/clean_fcctr.sh

## direct CLI
# perf record --call-graph dwarf -e major-faults,minor-faults make test
# perf report > perf_report.txt