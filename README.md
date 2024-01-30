# Fibonacci

A fibonacci number calculator algorithm for the n-th number in the Fibonacci sequence in Assembly 8086 microprocessor.

The program takes a number from a file and places its Fibonacci number in an output file.

numSize dictates the maximum buffer size that the number can represent.

# Running the program

It is suggested to use the latest version of [DOSBox](https://www.dosbox.com/) to run your program.

Use the [TASM](/TASM.zip) to compile and run your program.

```sh
tasm Fibonacci.asm
```

```sh
tlink Fibonacci.obj
```

Now you should have the executable and be ready to run the program.

```sh
Fibonacci inputFile.txt resultFile.txt
```

# Conclusion

If you have any advice for me or suggestions on how the program could be improved please feel free to share.

The program still has improvements to be made and struggles from several issues that should be fixed in the near future.

Todo:

- [ ] Fix blank file producing '0' as result.
- [ ] Increase number cap.
