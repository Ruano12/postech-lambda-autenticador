exports.handler = async (event) => {
  console.log("Evento recebido:", event);

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello from Lambda Node.js!" }),
  };
};