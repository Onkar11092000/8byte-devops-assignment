const request = require("supertest");
const app = require("../src/app");

describe("Root endpoint", () => {
  test("GET / should return application status", async () => {
    const response = await request(app)
      .get("/");

    expect(response.statusCode).toBe(200);

    expect(response.body).toEqual({
      message: "8Byte DevOps Demo Application",
      status: "running"
    });
  });
});