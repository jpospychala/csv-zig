CSV+Zig
=======

Simple Zig library to read CSV files.

Test 1: Reading large CSV file
------------------------------

For test purpse, we assume that large CSV file size is 1024 rows x 1024 cols.

First attempt at writing fast code in Zig falls short. Reading a CSV in Zig takes 3 orders of magnitude more time than similar code in JavaScript. After a brief examination it turns out that problem lies in the way how memory is allocated for CSV file cells. In Zig solution, each CSV cell gets it's own memory, whereas in JS solution we don't know it, but most likely entire CSV is stored in memory only once during CSV creation and later on memory is referenced in actual object.

Zig lesson number one: Managing memory by yourself is not necessairly efficient.


| Task                                 | Time (ms) |
|--------------------------------------|-----------|
| Creating sample CSV file in Zig      |       590 |
| Creating sample CSV file in Node.js  |       550 |
| Reading CSV file in Zig              |     10000 |
| Reading CSV file in Node.js          |       200 |


Test 2. Reading large CSV file optimized memory allocation
----------------------------------------------------------

Let's reimplement the CSV read code to reuse memory
TBD

