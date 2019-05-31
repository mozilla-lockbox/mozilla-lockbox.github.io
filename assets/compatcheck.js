---
---
document.addEventListener("DOMContentLoaded", () => {
    const CtoA = {
        "addon": {
            link: "{{ site.addon_link | escape }}",
            text: "Install for Firefox",
        },
        "upgrade": {
            link: "{{ site.fx_link | escape }}",
            text: "Upgrade Firefox",
        },
    }
    const addonBtn = document.querySelector("a.home__extension-link");
    const uaParams = /Firefox\/(.*)$/.exec(navigator.userAgent);
    if (!uaParams) {
        return;
    }
    const verParams = /(\d+).*$/.exec(uaParams[1]);
    const ver = parseInt((verParams && verParams[1]) || "0");

    let act;
    if (ver >= 67) {
        act = CtoA["addon"];
    } else {
        act = CtoA["upgrade"];
    }
    addonBtn.href = act.link;
    addonBtn.querySelector("p").textContent = act.text;
});
