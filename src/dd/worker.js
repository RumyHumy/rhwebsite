//importScripts("/lib/pyodide/pyodide.js");

// L O A D   P Y O D I D E

importScripts("https://cdn.jsdelivr.net/pyodide/v0.27.4/full/pyodide.js");

var output = "";

function print(msg) {
	postMessage({ type: 'print', data: msg });
	output += msg+"\n";
}

async function loadPyodideAndPackages() {
	self.pyodide = await loadPyodide({
		stdout: (text) => { print(text) },
		stderr: (text) => { print(text) },
	});
	postMessage({ type: 'loaded' });
}

loadPyodideAndPackages()

// R U N   &   T E S T

async function runCode(code) {
	if (!self.pyodide)
		return;
	try {
		await self.pyodide.runPythonAsync("import js\njs.pyodide.globals.clear()\n");
		const result = await self.pyodide.runPythonAsync(code);
		if (result !== undefined) {
			postMessage({ type: 'result', data: result });
		}
	} catch (error) {
		postMessage({ type: 'error', data: error.message });
	}
}

async function runTests(code, testData) {
	if (!self.pyodide || !testData)
		return;
	try {
		for (var i = 0; i < testData.length; i++) {
			await self.pyodide.runPythonAsync("import js\njs.pyodide.globals.clear()\n");
			const result = await self.pyodide.runPythonAsync(code);
			if (result !== undefined) {
				postMessage({ type: 'tests-result', data: result });
			}
		}
	} catch (error) {
		postMessage({ type: 'error', data: error.message });
	}
}

// M E S S A G E S

self.onmessage = async (event) => {
	const { type, code, testData } = event.data;
	switch (type) {
	case 'run':
		await runCode(code);
		break;
	case 'tests':
		await runTests(code, testData);
		break;
	}
};
