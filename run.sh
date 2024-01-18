./scripts/clean_fcctr.sh
./scripts/cloudlab/setup_node.sh
go build -race -v -a ./...
make trace > output.log 2>&1
code output.log


# Perf script 

# PERF_DATA_PATH="./perf.data"
# PERF_REPORT_TXT_PATH="./perf-report.txt"
# # REMOTE_HOST="user@remote_host"
# REMOTE_PERF_DATA_PATH="/remote/path/to/perf.data"
# LOCAL_PERF_DATA_PATH="/local/path/to/perf.data"

sudo perf record -e minor-faults -e major-faults -o $PERF_DATA_PATH -p $$ &
PERF_PID=$!

echo "Perf started with PID: $PERF_PID"

./scripts/cloudlab/setup_node.sh
go build -race -v -a ./...
make test 2>&1 | tee ./output

if ps -p $PERF_PID > /dev/null
then
   echo "Stopping perf with PID $PERF_PID"
   sudo kill -INT $PERF_PID
   wait $PERF_PID
else
   echo "Perf process not found"
fi

sudo perf report -i $PERF_DATA_PATH --stdio > $PERF_REPORT_TXT_PATH
./scripts/clean_fcctr.sh
scp $REMOTE_HOST:$REMOTE_PERF_DATA_PATH $LOCAL_PERF_DATA_PATH
