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
        console.log("API Response:", res); // Debugging
        document.getElementById("visitors").innerHTML = res.visitor_count;
      })
      .catch(error => console.error("Fetch Error:", error));
}

  
  // Wait for the DOM to load before calling the function
  document.addEventListener('DOMContentLoaded', function() {
    updateCounter();
  });
  