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

Let's reimplement the CSV read code to reuse memory.


| Task                                 | Time (ms) |
|--------------------------------------|-----------|
| CSV.readFromSlice#initialCapacity0   |       500 |
| CSV.readFromSlice#cap100             |       376 |
| CSV.readFromSlice#cap1024            |       240 |
| CSV.readFromSlice#cap1025            |       200 |

Now it's close to Node.js, although first version is on average 2x worse performance. In this version, after reading a separte line it's split into cols by field separator. All cols landing in a dedicated ArrayList. Given that in previous step, reducing numer of memory allocations took massive payoff, let's see if repeating the same trick can drive even better results. As you can see in the table above, answer is Yes. So the next place in code that does memory allocations is the moment when array is created to store row cols. By default, ArrayList in Zig has initial capacity 0. Initial capacity 100, sees visible improvement on time required to read whole CSV file.
The very best are last two cases. In last but one case, we allocate the initial ArrayList capacity one less than actually required and in the last case, we allocate the ArrayList with initial capacity equal the actually needed size - just as if the code had magic ball and was able to initially guess the needed array size. In magic ball iteration, our Zig implementation execution time finally matches Node.js impl. Yay!


Test 3. Does the Node.js have magic ball, or is it only generous with initial array capacities
----------------------------------------------------------------------------------------------

After the last experiment a question comes up whether JS impl "just knew" the capacity that is needed  when creating arrays for rows, or was it rather luck. In the case of luck, there must be some default capacity in JS such that with large enough CSV file we would eventually run into the scenario where default JS array capacity is too small whereas Zig "magic ball impl" would have it correct and that would make Zig run time win over Node.js result.
It turns out it's most likely yes. After growing the number of cols in sample CSV file by ten fold we can see that Node.js now takes more time to read such CSV, than the Zig impl which is adjusted to allocate arrays for each rows exactly the right size.
It is "Most likely" because there might be other factors kicking in, but that remains to be seen.


| Task                                 | Time (ms) |
|--------------------------------------|-----------|
| Zig CSV.readFromSlice#cap10241       |      1700 |
| Node.js csvread                      |      2100 |

