"use strict";

const fs = require("fs");
const jwt = require("jsonwebtoken");
const privateKey = fs.readFileSync("AuthKey.p8").toString();
const teamId = "3HZVZGMSN5";
const keyId = "J293WYD7YQ";
const jwtToken = jwt.sign({}, privateKey, {
	algorithm: "ES256",
	expiresIn: "1y",
	issuer: teamId,
	header: {
		alg: "ES256",
		kid: keyId
	}
});

console.log(jwtToken);
