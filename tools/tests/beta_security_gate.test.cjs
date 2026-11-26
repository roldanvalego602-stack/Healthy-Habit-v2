"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {inspectRules, inspectRepository} = require("../beta_security_gate.cjs");
const path = require("node:path");

const header = "rules_version = '2'; service cloud.firestore { match /databases/{database}/documents {";
const footer = "}}";

test("detecta la regla global que abre la base nombrada default", () => {
  const rules = header +
    "match /{document=**} { allow read, write: if request.auth != null; }" +
    footer;
  assert.match(inspectRules(rules).join(" "), /Regla global/);
});

test("detecta permisos generales de escritura al sistema", () => {
  const rules = header +
    "match /system/{document=**} { allow read, write: if request.auth != null; }" +
    footer;
  assert.match(inspectRules(rules).join(" "), /Configuración de sistema/);
});

test("no señala como abierta una regla que solo permite leer los propios datos", () => {
  const rules = header +
    "match /users/{uid} { allow read: if request.auth != null && request.auth.uid == uid; }" +
    "match /{document=**} { allow read, write: if false; }" + footer;
  assert.deepEqual(inspectRules(rules), []);
});

test("la configuración sin encabezado reconocible se rechaza", () => {
  assert.match(inspectRules("allow read, write: if true;").join(" "), /encabezado/);
});

test("no confunde un permiso de propietario con una apertura global", () => {
  const rules = header +
    "match /users/{uid} { allow read, write: if request.auth != null && request.auth.uid == uid; }" +
    "match /{document=**} { allow read, write: if false; }" + footer;
  assert.equal(inspectRules(rules).length, 0);
});

test("bloquea las rutas económicas directas actualmente presentes", () => {
  const root = path.resolve(__dirname, "../..");
  const findings = inspectRepository(root);
  assert.ok(findings.some((message) => message.includes("Registrar hábito")));
  assert.ok(findings.some((message) => message.includes("Tienda")));
  assert.ok(findings.some((message) => message.includes("entorno demo")));
});
