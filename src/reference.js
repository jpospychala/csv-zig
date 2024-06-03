const assert = require('node:assert').strict;

function readcsv(str) {
    csv = {
        headers: undefined,
        rows: [],
    };
    for (var line of str.split('\n')) {
        const cols = line.split(',');
        if (csv.headers === undefined) {
            csv.headers = cols; 
        } else {
            csv.rows.push(cols);
        }
    }
    return csv;
}

function test_read() {
    const actual = readcsv(`lp,name,height
1,joe,200
2,luke,300`);
    const expected = {
        headers: ['lp', 'name', 'height'],
        rows: [
            ['1', 'joe', '200'],
            ['2', 'luke', '300']
        ]
    }
    assert.deepEqual(actual, expected);
}

function test_large_csv_read() {
    const start = new Date().getTime();
    var buf = "";
    const rows = 1024;
    const cols = 1024 * 10;

    for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
            buf += `row${r}col${c},`;
        }
        buf += '\n';
    }
    const now = new Date().getTime();

    const csv = readcsv(buf);
    const then = new Date().getTime();

    console.log(`create ${now-start} read ${then-now} ms\n`);
}

test_read();    
test_large_csv_read();