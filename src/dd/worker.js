importScripts("/lib/pyodide/pyodide.js");

async function loadPyodideAndPackages() {
	self.pyodide = await loadPyodide({
		stdout: (text) => { postMessage({ type: 'print', data: text }); },
		stderr: (text) => { postMessage({ type: 'print', data: text }); },
	});
	postMessage({ type: 'loaded' });
}
loadPyodideAndPackages()

self.onmessage = async (event) => {
	const { code } = event.data;
	try {
		const result = await self.pyodide.runPythonAsync(code);
		if (result !== undefined) {
			postMessage({ type: 'result', data: result });
		}
	} catch (error) {
		postMessage({ type: 'error', data: error.message });
	}
};
