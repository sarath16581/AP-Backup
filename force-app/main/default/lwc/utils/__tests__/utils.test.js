import { isBlank, isNotBlank } from "../utils";

describe("utils.isBlank()", () => {
  it("returns 'true' for a blank string", () => {
    expect(isBlank("")).toBe(true);
  });

  it("returns 'true' for a whitespace string", () => {
    expect(isBlank(" ")).toBe(true);
  });

  it("returns 'true' for an undefined value", () => {
    expect(isBlank(undefined)).toBe(true);
  });

  it("returns 'true' for a null value", () => {
    expect(isBlank(null)).toBe(true);
  });

  it("returns 'false' for a string which is not blank", () => {
    expect(isBlank("hello world")).toBe(false);
  });

  it("returns 'false' for a whitespace string (allowWhitespace: true)", () => {
    expect(isBlank(" ", { allowWhitespace: true })).toBe(false);
  });

  it("throws an error for invalid input type", () => {
    expect(() => {
      isBlank({ hello: "world " });
    }).toThrow("'object' is not a string");
  });
});

describe("utils.isNotBlank", () => {
  it("returns 'false' for a blank string", () => {
    expect(isNotBlank("")).toBe(false);
  });

  it("returns 'false' for a whitespace string", () => {
    expect(isNotBlank(" ")).toBe(false);
  });

  it("returns 'false' for an undefined value", () => {
    expect(isNotBlank(undefined)).toBe(false);
  });

  it("returns 'false' for a null value", () => {
    expect(isNotBlank(null)).toBe(false);
  });

  it("returns 'true' for a string which is not blank", () => {
    expect(isNotBlank("hello world")).toBe(true);
  });

  it("returns 'true' for a whitespace string (allowWhitespace: true)", () => {
    expect(isNotBlank(" ", { allowWhitespace: true })).toBe(true);
  });

  it("throws an error for invalid input type", () => {
    expect(() => {
      isNotBlank({ hello: "world " });
    }).toThrow("'object' is not a string");
  });
});
