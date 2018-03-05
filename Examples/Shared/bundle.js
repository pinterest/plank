'use strict';

// Some helper to throw exceptions within JS

function assert(condition, message) {
  if (!condition) {
    message = message || 'Assertion failed';
    if (typeof Error !== 'undefined') {
      throw new Error(message);
    }
    throw message; // Fallback
  }
}

// Testing funtions

function getTestImageModelJSON() {
  return {
    height: 300,
    width: 200,
    url: 'https://picsum.photos/200/300',
  };
}

function sendTestImageModelJSON(passed) {
  const expected = getTestImageModelJSON();

  return (
    expected.height === passed.height &&
    expected.width === passed.width &&
    expected.url === passed.url
  );
}
