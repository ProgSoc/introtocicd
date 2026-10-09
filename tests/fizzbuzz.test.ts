// Checks the FizzBuzz logic in src/fizzbuzz.ts.
// No page and no server: call the function, compare the answer.
//
// `it.each` runs one test per row of the table, like pytest's parametrize.
// In the test name, %i and %s are filled in with that row's number and answer.
import { describe, expect, it } from "vitest";
import { fizzbuzz } from "../src/fizzbuzz.js";

describe("fizzbuzz", () => {
  it.each([
    [1, "1"],
    [2, "2"],
    [3, "Fizz"],
    [5, "Buzz"],
    [7, "7"],
    [9, "Fizz"],
    [10, "Buzz"],
    [15, "FizzBuzz"],
    [30, "FizzBuzz"],
    [45, "FizzBuzz"],
  ])("fizzbuzz(%i) is %s", (n, expected) => {
    expect(fizzbuzz(n)).toBe(expected);
  });

  it.each([
    [-3, "Fizz"],
    [-5, "Buzz"],
    [-15, "FizzBuzz"],
    [-7, "-7"],
  ])("negative: fizzbuzz(%i) is %s", (n, expected) => {
    expect(fizzbuzz(n)).toBe(expected);
  });

  // 0 is divisible by 15, so the function says FizzBuzz.
  // That's why main.ts has to check for 0 (quit) before calling it.
  it("fizzbuzz(0) is FizzBuzz", () => {
    expect(fizzbuzz(0)).toBe("FizzBuzz");
  });
});
