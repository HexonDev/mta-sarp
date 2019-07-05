
availableShopInteriors = {
    [15] = true,
    [1] = true,
	--[6] = true,
	--[18] = true
}

shopMarkers = {
    [15] = {
        {217.42391967773, -98.629219055176, 1005.2578125},
        {216.95573425293, -101.15849304199, 1005.2578125},
    },
    [1] = {
        {199.38710021973, -34.801616668701, 1002.3040161133},
        {209.49971008301, -34.004146575928, 1001.9296875},
    },
}

shopAssistants = {
	[15] = {
        {208.83032226563, -98.705139160156, 1005.2578125, 180, 100, "Eladó csávó"},
    },
    [1] = {
        {203.72482299805, -41.67085647583, 1001.8046875, 180, 100, "Eladó csávó"},
    },
}

availableSkins = {
    --[[male = {
        0, 1, 2, 7, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 57, 58, 59, 60, 61, 62, 66, 67, 68, 70, 71, 72, 73, 78, 79, 80, 81, 82, 83, 84, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 120, 121, 122, 123, 124, 125, 126, 127, 128, 132, 133, 134, 135, 136, 137, 142, 143, 144, 146, 147, 153, 154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 170, 171, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 200, 202, 203, 204, 206, 209, 210, 212, 213, 217, 220, 221, 222, 223, 227, 228, 229, 230, 234, 235, 236, 239, 240, 241, 242, 247, 248, 249, 250, 252, 253, 254, 255, 258, 259, 260, 261, 262, 264, 265, 266, 267, 268, 269, 270, 271, 272, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 290, 291, 292, 293, 294, 295, 296, 297, 299, 300, 301, 302, 303, 305, 306, 307, 308, 309, 310, 311, 312 
    },
    female = {
        9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 76, 77, 85, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 139, 140, 141, 145, 148, 150, 151, 152, 157, 169, 172, 178, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 226, 231, 232, 233, 237, 238, 243, 244, 245, 246, 251, 256, 257, 263, 298, 304
    }]]--

    male = {
        [7] = {"Garbós felső, láncos fehér, férfi.", 110},
        [14] = {"Dzsekis, szemüveges fehér, férfi.", 110},
        [15] = {"Fekete felsős, rasztás hajú, barnás férfi.", 110},
        [17] = {"Sport dzsekis, borostás, fehér férfi.", 110},
        [18] = {"Adidas szettes, fehér férfi.", 110},
        [19] = {"Fehér inges japán, férfi.", 110},
        [20] = {"Bőrdzsekis, borostás, fehér férfi.", 110},
        [21] = {"Pólós, Baseball sapkás, fehér férfi.", 110},
        [22] = {"Kockás inges, idősebb, fehér férfi.", 110},
        [23] = {"Mintáspólós, láncos, fehér férfi", 110},
        [34] = {"Kockás inges, fehér pólós, idősebb, fehér férfi.", 110},
        [46] = {"Fehér inges, olasz fehér férfi.", 110},
        [47] = {"Piros sapkás, zöld felsős, fekete férfi.", 110},
        [48] = {"Jordan pulcsis, fekete férfi.", 110},
        [49] = {"Fekete hosszú újju, fekete férfi.", 110},
        [50] = {"Arany láncos, fekete felsős, fekete férfi.", 110},
        [51] = {"Baseball sapkás, fehér felsős, fekete férfi.", 110},
        [52] = {"Hosszú fehér felsős, fekete férfi.", 110},
        [53] = {"Tattoovált, fekete felsős, fekete férfi.", 110},
        [54] = {"Jordan, sportos felsős, fekete férfi.", 110},
        [55] = {"Ralph Lauren felsős, fekete férfi.", 110},
        [56] = {"Halászsapkás, fekete férfi.", 110},
  		[57] = {"Fehér Lacoste felsős, fehér férfi.", 110},
  		[58] = {"Zöld-piros színű, mintás inges, fehér férfi.", 110},
  		[59] = {"Kék-fehér színű, virág mintás inges, fehér férfi.", 110},
    	[60] = {"Kockás inges, fehér férfi.", 110},
  		[62] = {"Fekete-arany Adidas melegítős, fehér férfi.", 110},
  		[66] = {"Ballonkabátos, kaukázusi férfi.", 110},
    	[67] = {"Nagydarab szürke inges, fehér férfi.", 110},
  		[68] = {"Idős szemüveges francia sapkás, fehér férfi.", 110},
  		[69] = {"Armani inges, fekete szemüveges, arany órás, kaukázusi férfi.", 110},
    	[70] = {"Öltönyös, fekete inges, Armani öves, fehér férfi.", 110},
    },

    female = {
        [9] = {"Piros trikós, barna hajú nő.", 110},
        [10] = {"Fekete pólós, szőke hajú nő.", 110},
        [11] = {"Fehér felsős, barna hajú nő.", 110},
        [12] = {"Fehér pólós, rövid hajú nő.", 110},
        [13] = {"Rózsaszín felső copfos hajú nő.", 110},
    }
}
