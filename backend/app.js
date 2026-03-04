const express = require("express");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");

// Charger le bon fichier .env selon l'environnement
const environment = process.env.NODE_ENV || "development";
require("dotenv").config({
  path: environment === "test" ? ".env.test" : ".env",
});

// Connexions à la BDD
const { db, dbTest } = require("./db");

const app = express();
app.use(cors());
app.use(express.urlencoded({ limit: "10mb", extended: true }));
app.use(express.json({ limit: "10mb" }));

const getDB = (req) => (req.path.startsWith("/test") ? dbTest : db);

// --- INSCRIPTION UTILISATEUR ---
app.post(["/register", "/test/register"], (req, res) => {
  const {
    nomUtilisateur,
    prénomUtilisateur,
    dateNaissanceUtilisateur,
    sexeUtilisateur,
    pseudoUtilisateur,
    emailUtilisateur,
    motDePasseUtilisateur,
  } = req.body;

  const idUtilisateur = uuidv4();
  const reformattedDate = dateNaissanceUtilisateur
    .split("/")
    .reverse()
    .join("-");

  const sql = `
    INSERT INTO Utilisateurs
    (idUtilisateur, nomUtilisateur, prénomUtilisateur, dateNaissanceUtilisateur, sexeUtilisateur, pseudoUtilisateur, emailUtilisateur, motDePasseUtilisateur, statusUtilisateur, Roles_idRole)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'activé', 1)
  `;

  const conn = getDB(req);
  conn.query(
    sql,
    [
      idUtilisateur,
      nomUtilisateur,
      prénomUtilisateur,
      reformattedDate,
      sexeUtilisateur,
      pseudoUtilisateur,
      emailUtilisateur,
      motDePasseUtilisateur,
    ],
    (err) => {
      if (err) {
        console.error("Erreur d'inscription :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      res.status(201).json({ message: "Utilisateur inscrit avec succès !" });
    }
  );
});

// --- CONNEXION UTILISATEUR ---
app.post(["/login", "/test/login"], (req, res) => {
  const { emailUtilisateur, motDePasseUtilisateur } = req.body;

  const sql = `
    SELECT * FROM Utilisateurs
    WHERE emailUtilisateur = ? AND motDePasseUtilisateur = ?
  `;

  const conn = getDB(req);
  conn.query(sql, [emailUtilisateur, motDePasseUtilisateur], (err, results) => {
    if (err) {
      console.error("Erreur lors de la connexion :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: "Email ou mot de passe incorrect" });
    }

    const utilisateur = results[0];

    // Vérification du statut
    if (utilisateur.statusUtilisateur === "désactivé") {
      return res.status(403).json({
        error: "Compte suspendu. Veuillez contacter l'administrateur.",
      });
    }

    res.status(200).json({
      message: "Connexion réussie",
      utilisateur: {
        id: utilisateur.idUtilisateur,
        nom: utilisateur.nomUtilisateur,
        prénom: utilisateur.prénomUtilisateur,
        email: utilisateur.emailUtilisateur,
        pseudo: utilisateur.pseudoUtilisateur,
        role: utilisateur.Roles_idRole,
      },
    });
  });
});

// --- RÉCUPÉRATION DES CATÉGORIES ---
app.get(["/categories", "/test/categories"], (req, res) => {
  const conn = getDB(req);
  conn.query(
    "SELECT idCatégorie, nomCatégorie, descriptionCatégorie FROM Catégories",
    (err, results) => {
      if (err) {
        console.error("Erreur lors de la requête SQL :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      res.json(results);
    }
  );
});

// --- AJOUT DE RESSOURCE ---
app.post(["/resources", "/test/resources"], (req, res) => {
  const {
    title,
    message,
    date,
    image, // base64
    userId,
    status,
    category,
  } = req.body;

  if (!title || !message || !date) {
    return res.status(400).json({ error: "Champs requis manquants" });
  }

  const conn = getDB(req);
  const imageBuffer = image ? Buffer.from(image, "base64") : null;

  const categorySql = `SELECT idCatégorie FROM Catégories WHERE nomCatégorie = ?`;

  conn.query(categorySql, [category], (err, categoryResults) => {
    if (err || categoryResults.length === 0) {
      console.error("Erreur de catégorie :", err);
      return res.status(400).json({ error: "Catégorie invalide" });
    }

    const categoryId = categoryResults[0].idCatégorie;

    const sql = `
      INSERT INTO Ressources (
        titreRessource,
        messageRessource,
        dateRessource,
        imageRessource,
        Utilisateurs_idUtilisateur,
        statusRessource,
        Catégories_idCatégorie
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `;

    conn.query(
      sql,
      [
        title,
        message,
        date,
        imageBuffer,
        userId || null,
        status || "affiche",
        categoryId,
      ],
      (err) => {
        if (err) {
          console.error("Erreur lors de l'ajout de la ressource :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }
        res.status(201).json({ message: "Ressource ajoutée avec succès !" });
      }
    );
  });
});

// --- PROFIL UTILISATEUR ---
app.get(
  ["/profil/:idUtilisateur", "/test/profil/:idUtilisateur"],
  (req, res) => {
    const { idUtilisateur } = req.params;
    const conn = getDB(req);

    const sql = `
    SELECT nomUtilisateur as nom,
           prénomUtilisateur as prénom,
           dateNaissanceUtilisateur as dateNaissance,
           sexeUtilisateur as sexe,
           pseudoUtilisateur as pseudo,
           emailUtilisateur as email,
           Roles_idRole as role
    FROM Utilisateurs
    WHERE idUtilisateur = ?
  `;

    conn.query(sql, [idUtilisateur], (err, results) => {
      if (err) {
        console.error("Erreur lors de la récupération du profil :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }

      if (results.length === 0) {
        return res.status(404).json({ error: "Utilisateur non trouvé" });
      }

      const utilisateur = results[0];
      if (utilisateur.dateNaissance) {
        const date = new Date(utilisateur.dateNaissance);
        utilisateur.dateNaissance = date.toLocaleDateString("fr-FR");
      }

      res.status(200).json({ utilisateur });
    });
  }
);

// --- MODIFIER PROFIL ---
app.put(
  ["/profil/:idUtilisateur/edit", "/test/profil/:idUtilisateur/edit"],
  (req, res) => {
    const { idUtilisateur } = req.params;
    const { nom, prénom, pseudo, email } = req.body;

    const sql = `
    UPDATE Utilisateurs
    SET nomUtilisateur = ?,
        prénomUtilisateur = ?,
        pseudoUtilisateur = ?,
        emailUtilisateur = ?
    WHERE idUtilisateur = ?
  `;

    const conn = getDB(req);
    conn.query(
      sql,
      [nom, prénom, pseudo, email, idUtilisateur],
      (err, result) => {
        if (err) {
          console.error("Erreur lors de la mise à jour du profil :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }

        if (result.affectedRows === 0) {
          return res.status(404).json({ error: "Utilisateur non trouvé" });
        }

        res.status(200).json({ message: "Profil mis à jour avec succès" });
      }
    );
  }
);

// --- MODIFIER MOT DE PASSE ---
app.put(
  ["/profil/:idUtilisateur/password", "/test/profil/:idUtilisateur/password"],
  (req, res) => {
    const { idUtilisateur } = req.params;
    const { ancienMotDePasse, nouveauMotDePasse } = req.body;

    const conn = getDB(req);
    conn.query(
      "SELECT idUtilisateur, motDePasseUtilisateur FROM Utilisateurs WHERE idUtilisateur = ?",
      [idUtilisateur],
      (err, results) => {
        if (err) {
          console.error(
            "Erreur lors de la récupération de l'utilisateur :",
            err
          );
          return res.status(500).json({ error: "Erreur serveur" });
        }

        if (results.length === 0) {
          return res.status(404).json({ error: "Utilisateur non trouvé" });
        }

        const utilisateur = results[0];
        if (utilisateur.motDePasseUtilisateur !== ancienMotDePasse) {
          return res
            .status(401)
            .json({ error: "Ancien mot de passe incorrect" });
        }

        const sql = `
          UPDATE Utilisateurs
          SET motDePasseUtilisateur = ?
          WHERE idUtilisateur = ?
        `;

        conn.query(sql, [nouveauMotDePasse, idUtilisateur], (err) => {
          if (err) {
            console.error(
              "Erreur lors de la mise à jour du mot de passe :",
              err
            );
            return res.status(500).json({ error: "Erreur serveur" });
          }

          res
            .status(200)
            .json({ message: "Mot de passe mis à jour avec succès" });
        });
      }
    );
  }
);

// --- RESSOURCES PAR CATÉGORIE ---
app.get(["/ressources", "/test/ressources"], (req, res) => {
  const { categorie } = req.query;
  if (!categorie) {
    return res.status(400).json({ error: "Catégorie manquante" });
  }

  const sql = `
    SELECT r.idRessource, r.titreRessource, r.messageRessource,

           r.dateRessource, r.statusRessource, r.imageRessource,
           u.pseudoUtilisateur
    FROM Ressources r
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    LEFT JOIN Utilisateurs u ON r.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE c.nomCatégorie = ? AND r.statusRessource = 'affiche'

    ORDER BY r.dateRessource DESC`;
  const conn = getDB(req);
  conn.query(sql, [categorie], (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des ressources :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    const ressources = results.map((ressource) => ({
      ...ressource,
      imageRessource: ressource.imageRessource
        ? Buffer.from(ressource.imageRessource).toString("base64")
        : null,
    }));


    res.json(ressources);
  });
});
// --- RESSOURCES PAR CATÉGORIE ---
app.get(["/ressources", "/test/ressources"], (req, res) => {
  const { categorie } = req.query;
  if (!categorie) {
    return res.status(400).json({ error: "Catégorie manquante" });
  }

  const sql = `SELECT r.idRessource, r.titreRessource, r.messageRessource,
           r.dateRessource, r.statusRessource, r.imageRessource,
           u.pseudoUtilisateur
    FROM Ressources r
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    LEFT JOIN Utilisateurs u ON r.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE c.nomCatégorie = ? AND r.statusRessource = 'affiche'
    ORDER BY r.dateRessource DESC`;
  const conn = getDB(req);
  conn.query(sql, [categorie], (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération des ressources :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    const ressources = results.map((ressource) => ({
      ...ressource,
      imageRessource: ressource.imageRessource
        ? Buffer.from(ressource.imageRessource).toString("base64")
        : null,
    }));

    res.json(ressources);
  });
});

// --- RESSOURCES PAR UTILISATEUR ---
app.get("/ressources/user/:idUtilisateur", (req, res) => {
  const { idUtilisateur } = req.params;

  const sql = `
    SELECT r.idRessource, r.titreRessource AS titre, r.messageRessource AS description,
           r.dateRessource, r.statusRessource, r.imageRessource, c.nomCatégorie AS nomCategorie
    FROM Ressources r
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    WHERE r.Utilisateurs_idUtilisateur = ?
    ORDER BY r.dateRessource DESC
  `;

  db.query(sql, [idUtilisateur], (err, results) => {
    if (err) {
      console.error(
        "Erreur lors de la récupération des ressources utilisateur :",
        err
      );
      return res.status(500).json({ error: "Erreur serveur" });
    }

    const ressources = results.map((ressource) => ({
      ...ressource,
      imageRessource: ressource.imageRessource
        ? Buffer.from(ressource.imageRessource).toString("base64")
        : null,
    }));

    res.status(200).json({ ressources });
  });
});

// --- RESSOURCES TOUTES CATEGORIES ---
app.get("/ressourcesAll", (req, res) => {
  const sql = `
    SELECT r.idRessource, r.titreRessource, r.messageRessource, r.dateRessource,
           r.statusRessource, r.imageRessource,
           r.Catégories_idCatégorie, c.nomCatégorie,
           r.Utilisateurs_idUtilisateur, u.pseudoUtilisateur
    FROM Ressources r
    JOIN Utilisateurs u ON r.Utilisateurs_idUtilisateur = u.idUtilisateur
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    WHERE r.statusRessource = 'affiche'
    ORDER BY r.dateRessource DESC
  `;

  db.query(sql, (err, results) => {
    if (err) {
      console.error("Erreur récupération ressources:", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    results.forEach((r) => {
      if (r.imageRessource) {
        r.imageRessource = Buffer.from(r.imageRessource).toString("base64");
      }
    });

    res.status(200).json(results);
  });
});

// --- GESTION DES UTILISATEURS (ADMIN) ---
app.get(["/utilisateurs", "/test/utilisateurs"], (req, res) => {
  const conn = getDB(req);
  conn.query(
    "SELECT idUtilisateur as id, pseudoUtilisateur as pseudo, emailUtilisateur as email, statusUtilisateur as status, Roles_idRole as role FROM Utilisateurs",
    (err, results) => {
      if (err) {
        console.error("Erreur lors de la récupération des utilisateurs :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      res.json(results);
    }
  );
});

// Suspendre un utilisateur (désactiver le compte)
app.patch(
  ["/utilisateurs/:id/suspendre", "/test/utilisateurs/:id/suspendre"],
  (req, res) => {
    const { id } = req.params;
    const { statusUtilisateur } = req.body; // attend 'désactivé' ou 'activé'
    const conn = getDB(req);

    // Par défaut, on désactive si rien n'est précisé
    const newStatus = statusUtilisateur === "activé" ? "activé" : "désactivé";

    conn.query(
      "UPDATE Utilisateurs SET statusUtilisateur = ? WHERE idUtilisateur = ?",
      [newStatus, id],
      (err, result) => {
        if (err) {
          console.error("Erreur lors de la suspension :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }
        if (result.affectedRows === 0) {
          return res.status(404).json({ error: "Utilisateur non trouvé" });
        }
        res.json({
          message: `Utilisateur ${
            newStatus === "désactivé" ? "suspendu" : "activé"
          } avec succès`,
        });
      }
    );
  }
);

// Supprimer un utilisateur
app.delete(["/utilisateurs/:id", "/test/utilisateurs/:id"], (req, res) => {
  const { id } = req.params;
  const conn = getDB(req);
  conn.query(
    "DELETE FROM Utilisateurs WHERE idUtilisateur = ?",
    [id],
    (err, result) => {
      if (err) {
        console.error("Erreur lors de la suppression :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: "Utilisateur non trouvé" });
      }
      res.json({ message: "Utilisateur supprimé avec succès" });
    }
  );
});

// --- RESSOURCES MASQUÉES (ADMIN) ---
app.get(["/resources_admin", "/test/resources_admin"], (req, res) => {
  const conn = getDB(req);
  const sql = `
    SELECT r.idRessource, r.titreRessource AS title, r.messageRessource AS message,
           r.dateRessource AS date, r.statusRessource AS status, r.imageRessource AS image,
           c.nomCatégorie AS categorie
    FROM Ressources r
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    WHERE r.statusRessource = 'masque'
    ORDER BY r.dateRessource DESC
  `;
  conn.query(sql, (err, results) => {
    if (err) {
      console.error(
        "Erreur lors de la récupération des ressources masquées :",
        err
      );
      return res.status(500).json({ error: "Erreur serveur" });
    }
    const ressources = results.map((ressource) => ({
      ...ressource,
      image: ressource.image
        ? Buffer.from(ressource.image).toString("base64")
        : null,
    }));
    res.json(ressources);
  });
});

// --- MODIFIER UNE RESSOURCE ---
app.put("/ressources/:idRessource", (req, res) => {
  const { idRessource } = req.params;
  const { titre, message, categorie, image } = req.body;

  const sqlCat = `SELECT idCatégorie FROM Catégories WHERE nomCatégorie = ?`;
  db.query(sqlCat, [categorie], (err, results) => {
    if (err || results.length === 0) {
      return res.status(400).json({ error: "Catégorie invalide" });
    }

    const idCat = results[0].idCatégorie;
    const imageBuffer = image ? Buffer.from(image, "base64") : null;

    const sqlUpdate = `
      UPDATE Ressources
      SET titreRessource = ?,
          messageRessource = ?,
          Catégories_idCatégorie = ?,
          statusRessource = 'masque',
          imageRessource = ?
      WHERE idRessource = ?
    `;

    db.query(
      sqlUpdate,
      [titre, message, idCat, imageBuffer, idRessource],
      (err) => {
        if (err) {
          console.error("Erreur modification ressource :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }
        res.status(200).json({
          message: "Ressource modifiée avec succès (statut : masque)",
        });
      }
    );
  });
});

// --- SUPPRIMER UNE RESSOURCE ---
app.delete("/ressources/:idRessource", (req, res) => {
  const { idRessource } = req.params;

  // D'abord, supprimez les commentaires associés
  const deleteCommentsSql =
    "DELETE FROM Commentaires WHERE Ressources_idRessource = ?";
  db.query(deleteCommentsSql, [idRessource], (err, result) => {
    if (err) {
      console.error("Erreur lors de la suppression des commentaires :", err);
      return res.status(500).json({
        error: "Erreur serveur lors de la suppression des commentaires",
      });
    }

    // Ensuite, supprimez la ressource
    const deleteResourceSql = "DELETE FROM Ressources WHERE idRessource = ?";
    db.query(deleteResourceSql, [idRessource], (err, result) => {
      if (err) {
        console.error("Erreur lors de la suppression de la ressource :", err);
        return res.status(500).json({
          error: "Erreur serveur lors de la suppression de la ressource",
        });
      }
      res.status(200).json({ message: "Ressource supprimée avec succès" });
    });
  });
});

// Valider une ressource masquée
app.patch(
  ["/resources_admin/:id/valider", "/test/resources_admin/:id/valider"],
  (req, res) => {
    const conn = getDB(req);
    const { id } = req.params;
    // Si rien n'est envoyé, on force à 'affiche'
    const status = req.body.statusRessource || "affiche";
    conn.query(
      "UPDATE Ressources SET statusRessource = ? WHERE idRessource = ?",
      [status, id],
      (err, result) => {
        if (err) {
          console.error("Erreur lors de la validation de la ressource :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }
        res.json({ message: "Ressource validée" });
      }
    );
  }
);

// Supprimer une ressource masquée
app.delete(
  ["/resources_admin/:id", "/test/resources_admin/:id"],
  (req, res) => {
    const conn = getDB(req);
    const { id } = req.params;

    // D'abord, supprimez les commentaires associés
    const deleteCommentsSql =
      "DELETE FROM Commentaires WHERE Ressources_idRessource = ?";
    conn.query(deleteCommentsSql, [id], (err, result) => {
      if (err) {
        console.error("Erreur lors de la suppression des commentaires :", err);
        return res.status(500).json({
          error: "Erreur serveur lors de la suppression des commentaires",
        });
      }

      // Ensuite, supprimez la ressource
      const deleteResourceSql = "DELETE FROM Ressources WHERE idRessource = ?";
      conn.query(deleteResourceSql, [id], (err, result) => {
        if (err) {
          console.error("Erreur lors de la suppression de la ressource :", err);
          return res.status(500).json({
            error: "Erreur serveur lors de la suppression de la ressource",
          });
        }
        res.json({ message: "Ressource supprimée" });
      });
    });
  }
);

// --- Récupération des likes d'une ressource + si utilisateur a liké ---
app.get("/ressources/:id/likes/:userId", (req, res) => {
  const { id, userId } = req.params;

  const countSql = `
    SELECT COUNT(*) AS likeCount FROM Interactions
    WHERE Ressources_idRessource = ? AND typeInteraction = 'favori'
  `;

  const userSql = `
    SELECT * FROM Interactions
    WHERE Ressources_idRessource = ? AND Utilisateurs_idUtilisateur = ? AND typeInteraction = 'favori'
  `;

  db.query(countSql, [id], (err, countResults) => {
    if (err) return res.status(500).json({ error: "Erreur serveur" });

    db.query(userSql, [id, userId], (err2, userResults) => {
      if (err2) return res.status(500).json({ error: "Erreur serveur" });

      res.json({
        likeCount: countResults[0].likeCount,
        liked: userResults.length > 0,
      });
    });
  });
});

// --- Ajout ou suppression de like ---
app.post("/interactions", (req, res) => {
  const { userId, ressourceId } = req.body;

  const checkSql = `
    SELECT * FROM Interactions
    WHERE Utilisateurs_idUtilisateur = ? AND Ressources_idRessource = ? AND typeInteraction = 'favori'
  `;

  db.query(checkSql, [userId, ressourceId], (err, results) => {
    if (err) return res.status(500).json({ error: "Erreur serveur" });

    if (results.length > 0) {
      const deleteSql = `
        DELETE FROM Interactions
        WHERE Utilisateurs_idUtilisateur = ? AND Ressources_idRessource = ? AND typeInteraction = 'favori'
      `;
      db.query(deleteSql, [userId, ressourceId], (err) => {
        if (err) return res.status(500).json({ error: "Erreur suppression" });
        res.json({ liked: false });
      });
    } else {
      const insertSql = `
        INSERT INTO Interactions (Utilisateurs_idUtilisateur, Ressources_idRessource, typeInteraction, dateInteraction)
        VALUES (?, ?, 'favori', NOW())
      `;
      db.query(insertSql, [userId, ressourceId], (err) => {
        if (err) return res.status(500).json({ error: "Erreur ajout" });
        res.json({ liked: true });
      });
    }
  });
});

// --- Ajouter un commentaire ---
app.post("/ressources/:id/commentaire", (req, res) => {
  const { id } = req.params;
  const { userId, message } = req.body;

  if (!userId || !message) {
    return res.status(400).json({ error: "Champs manquants" });
  }

  const sql = `
    INSERT INTO Commentaires (messageCommentaire, dateCommentaire, Utilisateurs_idUtilisateur, Ressources_idRessource)
    VALUES (?, NOW(), ?, ?)
  `;

  db.query(sql, [message, userId, id], (err) => {
    if (err) {
      console.error("Erreur ajout commentaire :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.status(201).json({ message: "Commentaire ajouté" });
  });
});

// --- Récupérer les commentaires d'une ressource ---
app.get("/ressources/:id/commentaires", (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT c.messageCommentaire, c.dateCommentaire, u.pseudoUtilisateur AS pseudo
    FROM Commentaires c
    JOIN Utilisateurs u ON c.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE c.Ressources_idRessource = ?
    ORDER BY c.dateCommentaire DESC
  `;

  db.query(sql, [id], (err, results) => {
    if (err) {
      console.error("Erreur récupération commentaires :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.status(200).json(results);
  });
});

// --- AJOUTER UNE RÉPONSE À UN COMMENTAIRE ---
app.post("/commentaires/:idCommentaire/reponse", (req, res) => {
  const { idCommentaire } = req.params;
  const { userId, message } = req.body;

  if (!userId || !message) {
    return res.status(400).json({ error: "Champs manquants" });
  }

  // D'abord, vérifier que le commentaire parent existe
  const checkCommentSql = `
    SELECT Ressources_idRessource FROM Commentaires WHERE idCommentaire = ?
  `;

  db.query(checkCommentSql, [idCommentaire], (err, results) => {
    if (err) {
      console.error("Erreur vérification commentaire :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: "Commentaire parent non trouvé" });
    }

    const ressourceId = results[0].Ressources_idRessource;

    const sql = `
      INSERT INTO Commentaires (messageCommentaire, dateCommentaire, Utilisateurs_idUtilisateur, Ressources_idRessource, commentaire_parent_id)
      VALUES (?, NOW(), ?, ?, ?)
    `;

    db.query(sql, [message, userId, ressourceId, idCommentaire], (err) => {
      if (err) {
        console.error("Erreur ajout réponse :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }

      res.status(201).json({ message: "Réponse ajoutée" });
    });
  });
});

// --- RÉCUPÉRER LES COMMENTAIRES AVEC RÉPONSES D'UNE RESSOURCE ---
app.get("/ressources/:id/commentaires", (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT 
      c.idCommentaire,
      c.messageCommentaire, 
      c.dateCommentaire, 
      c.commentaire_parent_id,
      u.pseudoUtilisateur AS pseudo
    FROM Commentaires c
    JOIN Utilisateurs u ON c.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE c.Ressources_idRessource = ?
    ORDER BY 
      CASE WHEN c.commentaire_parent_id IS NULL THEN c.idCommentaire ELSE c.commentaire_parent_id END,
      c.commentaire_parent_id IS NULL DESC,
      c.dateCommentaire ASC
  `;

  db.query(sql, [id], (err, results) => {
    if (err) {
      console.error("Erreur récupération commentaires :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    // Organiser les commentaires avec leurs réponses
    const commentaires = [];
    const commentairesMap = {};

    results.forEach((comment) => {
      if (!comment.commentaire_parent_id) {
        // C'est un commentaire principal
        comment.reponses = [];
        commentaires.push(comment);
        commentairesMap[comment.idCommentaire] = comment;
      } else {
        // C'est une réponse
        if (commentairesMap[comment.commentaire_parent_id]) {
          commentairesMap[comment.commentaire_parent_id].reponses.push(comment);
        }
      }
    });

    res.status(200).json(commentaires);
  });
});

// --- RÉCUPÉRER LES RESSOURCES LIKÉES PAR UN UTILISATEUR ---
app.get("/utilisateur/:userId/likes", (req, res) => {
  const { userId } = req.params;

  const sql = `
    SELECT 
      r.idRessource,
      r.titreRessource,
      r.messageRessource,
      r.dateRessource,
      r.imageRessource,
      c.nomCatégorie,
      u.pseudoUtilisateur,
      i.dateInteraction
    FROM Interactions i
    JOIN Ressources r ON i.Ressources_idRessource = r.idRessource
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    JOIN Utilisateurs u ON r.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE i.Utilisateurs_idUtilisateur = ? 
      AND i.typeInteraction = 'favori'
      AND r.statusRessource = 'affiche'
    ORDER BY i.dateInteraction DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("Erreur récupération likes utilisateur :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    const ressources = results.map((ressource) => ({
      ...ressource,
      imageRessource: ressource.imageRessource
        ? Buffer.from(ressource.imageRessource).toString("base64")
        : null,
    }));

    res.status(200).json(ressources);
  });
});

// --- SUPPRIMER UNE RÉPONSE ---
app.delete("/commentaires/:idCommentaire", (req, res) => {
  const { idCommentaire } = req.params;
  const { userId } = req.body;

  // Vérifier que l'utilisateur est le propriétaire du commentaire
  const checkSql = `
    SELECT Utilisateurs_idUtilisateur FROM Commentaires WHERE idCommentaire = ?
  `;

  db.query(checkSql, [idCommentaire], (err, results) => {
    if (err) {
      console.error("Erreur vérification propriétaire :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: "Commentaire non trouvé" });
    }

    if (results[0].Utilisateurs_idUtilisateur !== userId) {
      return res.status(403).json({ error: "Non autorisé" });
    }

    // Supprimer d'abord les réponses si c'est un commentaire parent
    const deleteRepliesSql = `
      DELETE FROM Commentaires WHERE commentaire_parent_id = ?
    `;

    db.query(deleteRepliesSql, [idCommentaire], (err) => {
      if (err) {
        console.error("Erreur suppression réponses :", err);
        return res.status(500).json({ error: "Erreur serveur" });
      }

      // Puis supprimer le commentaire principal
      const deleteCommentSql = `
        DELETE FROM Commentaires WHERE idCommentaire = ?
      `;

      db.query(deleteCommentSql, [idCommentaire], (err) => {
        if (err) {
          console.error("Erreur suppression commentaire :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }

        res.status(200).json({ message: "Commentaire supprimé" });
      });
    });
  });
});

// --- PROFIL UTILISATEUR + LIKES ---
app.get("/profil/:idUtilisateur", (req, res) => {
  const { idUtilisateur } = req.params;

  const utilisateurSql = `
    SELECT nomUtilisateur as nom, 
           prénomUtilisateur as prénom, 
           dateNaissanceUtilisateur as dateNaissance,
           sexeUtilisateur as sexe, 
           pseudoUtilisateur as pseudo, 
           emailUtilisateur as email, 
           Roles_idRole as role
    FROM Utilisateurs 
    WHERE idUtilisateur = ?
  `;

  const likesSql = `
    SELECT 
      r.idRessource,
      r.titreRessource,
      r.messageRessource,
      r.dateRessource,
      r.imageRessource,
      c.nomCatégorie,
      u.pseudoUtilisateur,
      i.dateInteraction
    FROM Interactions i
    JOIN Ressources r ON i.Ressources_idRessource = r.idRessource
    JOIN Catégories c ON r.Catégories_idCatégorie = c.idCatégorie
    JOIN Utilisateurs u ON r.Utilisateurs_idUtilisateur = u.idUtilisateur
    WHERE i.Utilisateurs_idUtilisateur = ? 
      AND i.typeInteraction = 'favori'
      AND r.statusRessource = 'affiche'
    ORDER BY i.dateInteraction DESC
  `;

  db.query(utilisateurSql, [idUtilisateur], (err, results) => {
    if (err) {
      console.error("Erreur lors de la récupération du profil :", err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: "Utilisateur non trouvé" });
    }

    const utilisateur = results[0];
    if (utilisateur.dateNaissance) {
      const date = new Date(utilisateur.dateNaissance);
      utilisateur.dateNaissance = date.toLocaleDateString("fr-FR");
    }

    db.query(likesSql, [idUtilisateur], (err2, likes) => {
      if (err2) {
        console.error("Erreur récupération des likes :", err2);
        return res.status(500).json({ error: "Erreur serveur" });
      }

      const ressources = likes.map((ressource) => ({
        ...ressource,
        imageRessource: ressource.imageRessource
          ? Buffer.from(ressource.imageRessource).toString("base64")
          : null,
      }));

      res.status(200).json({ utilisateur, likes: ressources });
    });
  });
});

// --- CHANGER LE ROLE D'UN UTILISATEUR ---
app.patch(
  ["/utilisateurs/:id/role", "/test/utilisateurs/:id/role"],
  (req, res) => {
    const conn = getDB(req);
    const { id } = req.params;
    const { role } = req.body;
    conn.query(
      "UPDATE Utilisateurs SET Roles_idRole = ? WHERE idUtilisateur = ?",
      [role, id],
      (err, result) => {
        if (err) {
          console.error("Erreur lors du changement de rôle :", err);
          return res.status(500).json({ error: "Erreur serveur" });
        }
        res.json({ message: "Rôle mis à jour" });
      }
    );
  }
);

// --- LANCEMENT DU SERVEUR ---
app.listen(5000, () => {
  console.log(`Backend (${environment}) listening on port 5000`);
});
