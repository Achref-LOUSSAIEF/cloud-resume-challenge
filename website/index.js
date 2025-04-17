$(document).ready(function (e) {
    $win = $(window);
    $navbar = $('#header');
    $toggle = $('.toggle-button');
    var width = $navbar.width();
    toggle_onclick($win, $navbar, width);

    // resize event
    $win.resize(function () {
        toggle_onclick($win, $navbar, width);
    });

    $toggle.click(function (e) {
        $navbar.toggleClass("toggle-left");
    });
});

function toggle_onclick($win, $navbar, width) {
    if ($win.width() <= 768) {
        $navbar.css({ left: `-${width}px` });
    } else {
        $navbar.css({ left: '0px' });
    }
}

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();

        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

// This function fetches the visitor count and updates the HTML content
function updateCounter() {
    fetch('https://odoetmt010.execute-api.us-east-1.amazonaws.com/')
  .then(res => res.json())
  .then(res => {
    console.log("API Response:", res);
    if (document.getElementById("counter")) {
      document.getElementById("counter").innerHTML = `👀 Views: ${res.visitor_count}`;
    } else {
      console.error("Element with ID 'counter' not found!");
    }
  })
  .catch(error => console.error("Fetch Error:", error));
  }
  
// Wait for the DOM to load before calling the functions
document.addEventListener('DOMContentLoaded', function () {
    updateCounter();

    // Check for saved language preference (optional)
    const savedLang = localStorage.getItem("language") || "en";
    document.getElementById("languageSelect").value = savedLang;
    changeLanguage(savedLang);

    // Add the change listener to the dropdown
    document.getElementById("languageSelect").addEventListener("change", () => {
        const selectedLang = document.getElementById("languageSelect").value;
        localStorage.setItem("language", selectedLang); // Save user preference
        changeLanguage(selectedLang);
    });
});

// Main function to switch language
function changeLanguage(language) {
    const elements = document.querySelectorAll('[data-en]');
    elements.forEach(element => {
        const translation = element.getAttribute(`data-${language}`);
        if (translation) {
            element.innerHTML = translation; // Use innerHTML for rich content
        }
    });
}
