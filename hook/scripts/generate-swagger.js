require("dotenv").config();
const fs = require("fs");
const yaml = require("js-yaml");
const path = require("path");

// The instances you want to generate Swagger for
const instances = {
 main: require("../app/routes/root"),
};

// Backstage-specific header to prepend to the final YAML file
const backstageHeader = `
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: lis-proxy-api
  description: Microservice for managing communications with Santagostino Laboratory Information System (LIS).
  tags:
    - lis-proxy
spec:
  type: openapi
  lifecycle: production
  owner: 'santagostino'
  system: lab
  definition: |
`;

const cleanNullTypes = (yamlInput) => {
 const obj = typeof yamlInput === "string" ? yaml.load(yamlInput) : yamlInput;

 // Funzione ricorsiva per pulire i tipi
 const cleanTypes = (node) => {
  if (!node || typeof node !== "object") return node;

  if (Array.isArray(node)) {
   return node.map((item) => cleanTypes(item));
  }

  const cleaned = {};
  for (const [key, value] of Object.entries(node)) {
   if (key === "type" && Array.isArray(value)) {
    // Rimuoviamo 'null' dall'array dei tipi
    const types = value.filter((t) => t !== "null");
    if (types.length >= 1) {
     cleaned["nullable"] = true;
    }
    // Se rimane solo un tipo, lo mettiamo come stringa diretta
    cleaned[key] = types.length === 1 ? types[0] : types;
   } else {
    cleaned[key] = cleanTypes(value);
   }
  }
  return cleaned;
 };

 const cleanedObj = cleanTypes(obj);
 return yaml.dump(cleanedObj);
};

const generateAndMergeSwagger = async () => {
 global.generating = true;
 if (process.env.APP_ENV !== "local") {
  console.info(
   "GENERATE_SWAGGER is not set. Skipping Swagger YAML generation."
  );
  return;
 }

 const swaggerFiles = [];

 for (const [key, instance] of Object.entries(instances)) {
  try {
   await instance.ready();

   const swaggerJSON = instance.swagger({ yaml: true });
   const cleanedYaml = cleanNullTypes(swaggerJSON);
   const rnd = Math.floor(Math.random() * 1000);
   const tempFilePath = path.join(
    __dirname,
    "../api-docs/temp-" + rnd + ".yaml"
   );
   fs.writeFileSync(tempFilePath, cleanedYaml, "utf8");

   swaggerFiles.push(tempFilePath);

   await instance.close();
  } catch (error) {
   console.error(`Error generating Swagger for instance ${key}:`, error);
   process.exit(1);
  }
 }

 // all the Swagger files into one
 try {
  const mergedPaths = {};
  const mergedComponents = { securitySchemes: {} };
  const servers = [];

  for (const swaggerFile of swaggerFiles) {
   const swaggerData = yaml.load(fs.readFileSync(swaggerFile, "utf8"));

   // Merge paths and components
   Object.assign(mergedPaths, swaggerData.paths);
   Object.assign(
    mergedComponents.securitySchemes,
    swaggerData.components?.securitySchemes || {}
   );
   if (Array.isArray(swaggerData.servers)) {
    servers.push(...swaggerData.servers);
   }
  }

  // final merged Swagger document
  const mergedSwagger = {
   openapi: "3.0.0",
   info: {
    title: `${process.env.APP_NAME}`,
    version: "1.0.0",
    description:
     "Microservice for managing communications with Santagostino Laboratory Information System (LIS).",
    contact: {
     email: "noreply@santagostino.it",
    },
   },
   servers: [
    {
     url: "https://lis-proxy.santagostino-api.it/stage",
     description: "Stage server",
    },
    {
     url: "https://lis-proxy.santagostino-api.it",
     description: "Production server",
    },
   ],
   paths: mergedPaths,
   components: mergedComponents,
  };

  const mergedYamlString = yaml.dump(mergedSwagger);
  const finalYamlContent =
   backstageHeader +
   mergedYamlString
    .split("\n")
    .map((line) => "    " + line)
    .join("\n");

  const outputPath = path.join(__dirname, "../api-docs/lis-proxy-api.yaml");
  fs.writeFileSync(outputPath, finalYamlContent, "utf8");
  console.info(
   `Swagger YAML successfully generated and saved to ${outputPath}`
  );

  swaggerFiles.forEach((file) => fs.unlinkSync(file));
 } catch (error) {
  console.error("Error occurred during Swagger process:", error);
  process.exit(1);
 }
};

generateAndMergeSwagger();
