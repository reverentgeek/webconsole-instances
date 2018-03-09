'use strict';
const Cp = require('child_process');
const Path = require('path');
const Barrier = require('cb-barrier');
const Code = require('code');
const Lab = require('lab');

// Test shortcuts
const lab = exports.lab = Lab.script();
const { describe, it } = lab;
const { expect, fail } = Code;


describe('Instance Console', () => {
  it('successfully starts the server', () => {
    const barrier = new Barrier();
    const options = {
      env: {
        // Minimum environment needed for the server to start.
        SDC_URL: 'https://us-sw-1.api.joyentcloud.com'
      }
    };
    const child = Cp.spawn(process.execPath,
      [Path.resolve(__dirname, '..', 'index.js')], options);
    let stdout = '';

    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', fail);

    child.stdout.on('data', (data) => {
      stdout += data;

      if (/^server started at /.test(stdout)) {
        child.kill();
        expect(child.killed).to.equal(true);
        barrier.pass();
      }
    });

    return barrier;
  });
});
