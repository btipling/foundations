# Chapter 1 Representing Real Numbers

## 1. Introduction

integral types: int, uint, short
non-integral types: floating point numbers, real numbers

IEEE floating point format

real numbers are more complex, can overflow and cause other types of errors

## 1.2 Fixed point numbers

Fixed point move the decimal from integers from the last to a mid point in a byte (8 dot 0 vs 4 dot 4):

integer (2^0 - 2^7):        128  64   32   16 - 8    4    2   1
fixed point  (2^-4 - 2^3):  8    4    2    (1.1/2)  1/4  1/8  1/16

least significant bit is 1/16 ^^

difference between integer and fix point is a scaling factor, scaling is fixed in fixed point

fp scaling factor format A dot B

 u32 is 32 dot 0

real numbers must be approximated because it can't represent all values in a range

the error of an approximation between a repsentation of a number and is actual value is defined by R(A) - A

doesn't describe scale at which it affects computation

1km size accuracy range can't be good at measuring small objects 

relative error does describe scale by dividing (R(A) - A)/A as long as A is not approaching 0

fixed point - absolute error is bounded by a constant, relative error varies considerably

## 1.3 Floating point numbers

scientific notation is analogous to floating point numbers

mantissa is greater or equal to 1 and less than 10, a value 1 thru 10
exponent: an integer

scientific notation: mantissa * 10^exponent, 0 is just 0

number equality is mantissa and exponent are equal, normalization is important hence the mantissa range

range and precision is finite, limited no of values can be represented

have a max, min and smallest positive value

binary: sign * mantissa * (2 ^ (sign * exponent))

integral bit of mantissa is always 1 due to normalization

number of values can be represented is 1 bit less than integers 128 vs 256 values for 8 bites 

hole at 0

this system gets less precise the further it moves from 0

## 1.4 IEEE 754 FP standard

different formats, discusses 32 bit single precision, 64 bit double precision, 16 bit half precision

single precision: 1 bit sign, exponent is 8 bits, mantissa 23 bits

sign: explicit/high order bit: 0 pos 1 neg

pg 9 - tbc









