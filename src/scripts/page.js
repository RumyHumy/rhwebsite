function SetPageTitle(selector) {
	document.title = document.querySelector(selector).innerHTML;
}

function ElementVisibility(selector, state) {
	document.querySelectorAll(selector).forEach(tag => tag.style.display = (state ? 'inline' : 'none'));
}

function GetLangCode() {
	var lang = localStorage.getItem("lang");
	if (lang === null)
		lang = navigator.language || navigator.userLanguage;
	if (!lang)
		lang = "en";
	lang = lang.toLowerCase();
	return lang;
}

function SetLang() {
	var lang = GetLangCode();

	ElementVisibility(".title-ru", false);
	ElementVisibility(".title-en", false);

	if (lang.indexOf("ru") == 0) {
		ElementVisibility(".lang-en", false);
		ElementVisibility(".lang-ru", true);
		SetPageTitle(".title-ru");
	} else {
		ElementVisibility(".lang-en", true);
		ElementVisibility(".lang-ru", false);
		SetPageTitle(".title-en");
	}
}

function PageUpdate() {
	SetLang();
	// Get all media elements on the page
	const mediaElements = document.querySelectorAll('audio, video');
	// Add event listeners to each media element
	mediaElements.forEach(media1 => {
		media1.addEventListener('play', () => {
			mediaElements.forEach(media2 => {
				if (media2 !== media1) {
					media2.pause();
				}
			});
		});
	});
}

async function FetchText(fpath) {
	try {
		const response = await fetch(fpath);
		if (!response.ok) {
			console.error(`Failed to fetch file: ${response.status} ${response.statusText}`);
			return null;
		}
		return await response.text();
	} catch (error) {
		console.error('Error fetching file:', error);
		return null;
	}
}
