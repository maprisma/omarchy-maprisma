.pragma library

var words = {
  en: { title: "Install Maprisma?", body: "The Maprisma app is not on this PC yet. Install the latest AppImage for your user account? Its SHA-256 checksum is checked before it is opened. No administrator password is needed.", cancel: "Not now", install: "Install AppImage" },
  de: { title: "Maprisma installieren?", body: "Die Maprisma-App ist noch nicht auf diesem PC. Möchtest du das neueste AppImage für dein Benutzerkonto installieren? Vor dem Öffnen wird die SHA-256-Prüfsumme geprüft. Ein Administratorpasswort ist nicht nötig.", cancel: "Jetzt nicht", install: "AppImage installieren" },
  es: { title: "¿Instalar Maprisma?", body: "La aplicación Maprisma aún no está en este PC. ¿Quieres instalar el AppImage más reciente para tu cuenta? Se comprueba su suma SHA-256 antes de abrirlo. No hace falta contraseña de administrador.", cancel: "Ahora no", install: "Instalar AppImage" },
  fr: { title: "Installer Maprisma ?", body: "L’application Maprisma n’est pas encore sur ce PC. Installer le dernier AppImage pour votre compte ? Son empreinte SHA-256 est vérifiée avant l’ouverture. Aucun mot de passe administrateur n’est nécessaire.", cancel: "Pas maintenant", install: "Installer l’AppImage" },
  it: { title: "Installare Maprisma?", body: "L’app Maprisma non è ancora su questo PC. Vuoi installare l’AppImage più recente per il tuo account? La somma SHA-256 viene verificata prima dell’apertura. Non serve una password di amministratore.", cancel: "Non ora", install: "Installa AppImage" },
  nl: { title: "Maprisma installeren?", body: "De Maprisma-app staat nog niet op deze pc. Wil je de nieuwste AppImage voor je account installeren? De SHA-256-controlesom wordt gecontroleerd voordat de app opent. Een beheerderswachtwoord is niet nodig.", cancel: "Nu niet", install: "AppImage installeren" },
  pl: { title: "Zainstalować Maprisma?", body: "Aplikacji Maprisma nie ma jeszcze na tym komputerze. Zainstalować najnowszy AppImage dla Twojego konta? Przed uruchomieniem sprawdzana jest suma SHA-256. Hasło administratora nie jest potrzebne.", cancel: "Nie teraz", install: "Zainstaluj AppImage" },
  pt: { title: "Instalar o Maprisma?", body: "A aplicação Maprisma ainda não está neste PC. Quer instalar o AppImage mais recente para a sua conta? A soma SHA-256 é verificada antes de abrir. Não é necessária uma palavra-passe de administrador.", cancel: "Agora não", install: "Instalar AppImage" }
}

function language(value) {
  var code = String(value || "en").slice(0, 2).toLowerCase()
  return words[code] ? code : "en"
}

function text(lang, key) {
  var row = words[lang] || words.en
  return row[key] || words.en[key] || key
}
