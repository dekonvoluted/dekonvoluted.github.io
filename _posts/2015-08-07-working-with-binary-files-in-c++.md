---
title: Working with binary files in C++
layout: post
categories: [ C++ ]
tags: [ C++, binary ]
comments: true
---

Binary files are more efficient at storing numerical data in smaller file sizes than plain text.
As a result, most of the data we use and interact with everyday is usually in binary formats.
This post is about extracting data out of a binary file using C++.

To serve as an example, let's consider a binary file in a format called SPE.
This format is used by Princeton Instruments cameras to record images and spectra.
I worked with these files as a grad student, so I'm familiar with them.

According to the SPE format, the file begins with a 4100-byte header which stores lots of information about the settings used to capture the image, followed by the raw data that comprises the image frames.
For this post, I'll work with the the attribute for the number of columns present in the image.
This value is stored as a two-byte unsigned short integer forty-two bytes from the start of the file.
We can see this structure by using a hex editor (I recommend Okteta) or a viewer like `xxd`.

{% highlight console %}
$ xxd image.spe
00000000: 0400 0100 0200 0002 0100 17b7 5138 0000  ............Q8..
00000010: 0000 0002 3238 4665 6232 3030 3800 0000  ....28Feb2008...
00000020: 0000 ffff 0000 a0c1 3600 0002 0000 0000  ........6.......
00000030: 0000 0100 0000 0000 0000 0000 0000 0000  ................
...
{% endhighlight %}

The number of columns, at byte 42 (=0x2A, in hexadecimal) is on the third line and reads `0002`.
This is little-endian for `0200` (=0x200, in hexadecimal), which is 512 in decimal.
This image has 512 columns (which is true as this camera had a 512x512 sensor).
Now, let's look at the different ways to go about extracting this value with C++.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>

int main()
{
    unsigned short cols;

    // Extract the number of columns at 0x2A
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.seekg( 42 );
    inFile.read( reinterpret_cast<char*>( &cols ), sizeof( cols ) );
    inFile.close();

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

This is the simplest implementation
The file is opened for reading in the binary mode.
The file pointer is told to seek the 42nd byte, where it proceeds to read in two bytes (which is the size of an unsigned short) of data.
This is stored in the memory location where `cols` resides, which is presented to the `read` command as if it were a pointer to characters.
When executed, this will print out 512.

This approach is great if you want to read one value at a time.
However, you might want to read in larger blocks of data at once to minimize the number of read operations.
For instance, let's say we would like to read in the entire 4100 byte header in at once and then extract the metadata present in it at our convenience.
Working with the same principle, one might write the following code.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>

int main()
{
    char header[ 4100 ];

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( header, 4100 );
    inFile.close();

    // Extract the number of columns at 0x2A
    char colchars[ 2 ];
    colchars[ 0 ] = header[ 42 ];
    colchars[ 1 ] = header[ 43 ];
    unsigned short cols = *( unsigned short* ) colchars;

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

Now, we simply read 4100 bytes straight into a char array (with no need to `reinterpret_cast`) and slice the array to get two bytes at an offset of 42.
These two bytes are cast as an unsigned short and we have the number of columns.
This code will work just fine, but when compiling, it will print this warning,

{% highlight console %}
file.cpp: In function ‘int main()’:
file.cpp:18:48: warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing]
     unsigned short cols = *( unsigned short* ) colchars;
                                                ^
{% endhighlight %}

The compiler is warning that a location in memory is being pointed to by two types of pointers.
Not the worst thing, but `-Wall` likes to play by the rules and that's something we should also try our best to do.
The legal way in C to have the same location accessible to two different data types is by using `union`s.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>

int main()
{
    char header[ 4100 ];

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( header, 4100 );
    inFile.close();

    // Extract the number of columns at 0x2A
    union {
        char colchars[ 2 ];
        unsigned short cols;
    } columns;
    columns.colchars[ 0 ] = header[ 42 ];
    columns.colchars[ 1 ] = header[ 43 ];

    std::cout << "Number of columns: " << columns.cols << std::endl;

    return 0;
}
{% endhighlight %}

No more compiler warnings!
However, some of the ways that C does things strikes me, as a C++ programmer, as odd.
The slicing of the char array is awkward, as is the use of unions to cast characters into numbers.
C++ provides some nice containers that ought to make the slicing part more natural.
Let's start with using a string instead of an array of characters.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>
#include <string>
#include <sstream>

int main()
{
    std::string header( 4100, 0 );

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( &header[ 0 ], 4100 );
    inFile.close();

    // Extract the number of columns at 0x2A
    unsigned short cols;
    std::stringstream( header.substr( 42, 2 ) ).read( reinterpret_cast<char*>( &cols ), sizeof( cols ) );

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

The slicing operation is now elegant and easy to follow.
There is however a dangerous operation being performed here.
Reading from the file directly into the string, using either `&header[ 0 ]` or the more appropriate `header.data()` to get the address of the first element is not recommended.
The C++ standard does not guarantee that a string will always be stored in a contiguous manner in memory.
This opens the door to a potential segmentation fault or worse in case we end up writing to regions of memory we shouldn't be overwriting.
In reality however, most implementations of the standard do indeed store the string in one contiguous block; still, we shouldn't really depend on that.
So, let's use a container that does guarantee this operation is always safe, `vector`.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>

int main()
{
    std::vector<char> header( 4100, 0 );

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( header.data(), 4100 );
    inFile.close();

    // Extract the number of columns at 0x2A
    std::string slice( header.begin() + 42, header.begin() + 44 );
    unsigned short cols;
    std::stringstream( slice ).read( reinterpret_cast<char*>( &cols ), sizeof( cols ) );

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

This addresses our concern about a possible segmentation fault and retrieves binary data correctly from the file header.
One last rewrite to make this code easier to read in the future.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <cstddef>

int main()
{
    const std::size_t HEADER_LENGTH = 4100;
    std::vector<char> header( HEADER_LENGTH, 0 );

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( header.data(), HEADER_LENGTH );
    inFile.close();

    // Extract the number of columns (unsigned short) at offset 42 (0x2A)
    unsigned short cols;
    const std::size_t OFFSET_COLS = header.begin() + 0x2A;
    const std::size_t LENGTH_COLS = sizeof( cols );

    std::string slice( OFFSET_COLS, OFFSET_COLS + LENGTH_COLS );
    std::stringstream( slice ).read( reinterpret_cast<char*>( &cols ), LENGTH_COLS );

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

The code now explains what the hard-coded numbers like 4100 and 42 are.
Lengths are typically easier to understand in decimal, but offsets are usually shown in hexadecimal by hex viewers.
So, it's simpler to use `0x2A` instead of `42`.
One last change is the use of the appropriate datatype `std::size_t` to store these values.
`size_t` is an unsigned integer type that is guaranteed to hold the size/index of any array.
`std::size_t` is the C++-friendly version of that.

Now, there's one last thing we can do to make this code a little more robust and that's to ensure that the `cols` variable is always exactly 16 bits long.
For that, we should use `std::uint16_t` instead of `unsigned short`.

{% highlight cpp lineanchors %}
#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <cstddef>
#include <cstdint>

int main()
{
    const std::size_t HEADER_LENGTH = 4100;
    std::vector<char> header( HEADER_LENGTH, 0 );

    // Extract the entire header
    std::ifstream inFile;
    inFile.open( "image.spe", std::ios::in | std::ios::binary );
    inFile.read( header.data(), HEADER_LENGTH );
    inFile.close();

    // Extract the number of columns (unsigned short) at offset 42 (0x2A)
    std::uint16_t cols;
    const std::size_t OFFSET_COLS = header.begin() + 0x2A;
    const std::size_t LENGTH_COLS = 2;

    std::string slice( OFFSET_COLS, OFFSET_COLS + LENGTH_COLS );
    std::stringstream( slice ).read( reinterpret_cast<char*>( &cols ), LENGTH_COLS );

    std::cout << "Number of columns: " << cols << std::endl;

    return 0;
}
{% endhighlight %}

We can now use this basic approach to read data from any point in the binary file and interpret it according to the spec for the format.

