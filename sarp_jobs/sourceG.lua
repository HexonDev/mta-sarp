jobs = {
    --[[
    [1] = {"Favágó", ":sarp_assets/images/jobs/1.png", "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent eget erat non tortor gravida aliquet ut mollis felis. Maecenas libero enim, tincidunt et est quis, porttitor rutrum lacus. Vivamus a placerat erat. Quisque mollis est a commodo tincidunt. Suspendisse suscipit nulla in est lacinia ultrices. Nulla eget lectus orci. Donec luctus, urna at aliquam auctor, ipsum quam molestie enim, in convallis purus nisi malesuada metus. Phasellus lacinia enim at eros tempus facilisis. Nunc auctor rhoncus lacus, in pharetra turpis mattis at. Nullam non enim nibh. Integer rhoncus, massa non venenatis mattis, dui risus rhoncus dolor, sed condimentum erat magna a."},
    [2] = {"Gépjármű-összeszerelő", ":sarp_assets/images/jobs/2.png", "leírás2"},
    [3] = {"Villanyszerelő", ":sarp_assets/images/jobs/3.png", "leírás3"},
    [4] = {"Bányász", ":sarp_assets/images/jobs/4.png", "leírás4"},
    ]]
    [1] = {
        "Raktáros",
        ":sarp_assets/images/jobs/1.png",
        "Válaszd, ki a megfelelő dobozokat a raktárból, majd a listának megfelelően címkézd fel őket!",
        0,
    },
    [2] = {
        "Fagylaltos",
        ":sarp_assets/images/jobs/2.png",
        "Cirkálj Los Santos utcáin, és szolgáld ki a vásárlókat, a kérésük szerint! Ha elfogy a fagylalt, a megfelelő helyen töltsd újra a készleteid!",
        0,
    },
    [3] = {
        "Bányász",
        ":sarp_assets/images/jobs/4.png",
        "Ki ne szeretne gazdag lenni, nem igaz? A bányában értékesebbnél, értékesebb ércekre találhatsz! A leadásnál, meglesz a várt eredmény!",
        0,
    },
    [4] = {
        "Felszolgáló",
        ":sarp_assets/images/jobs/3.png",
        "Menj el az egyik gyors étterembe. Vedd fel a megrendeléseket, készítsd el, majd vidd ki a vevőnek. Ha a munkádat gyorsan és odafigyelve végzed, akkor busás jutalomban lesz részed, mivel a vendégek mindig bő kezűek.",
        0
    },
    --[[[5] = {
        "Ablaktisztító",
        ":sarp_assets/images/jobs/5.png",
        "Sokak panaszkodnak, hogy nem látják Los Santos szépségét az ablakokon keresztül. A te feladatod, az ablakok megtisztítása!",
        0
    },]]
    --[[[6] = {
        "Úttisztító",
        ":sarp_assets/images/jobs/6.png",
        "Los Santos utcái piszkosak! A te feladatod, az lenne, hogy a tisztaság átvegye az uralmat az utak felett!",
        0
    },]]
}

function getJobInfo(jobID)
    if jobs[jobID] then
        return jobs[jobID]
    else
        return "Nincs"
    end
end