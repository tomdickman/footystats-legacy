"use strict";
var __makeTemplateObject = (this && this.__makeTemplateObject) || function (cooked, raw) {
    if (Object.defineProperty) { Object.defineProperty(cooked, "raw", { value: raw }); } else { cooked.raw = raw; }
    return cooked;
};
Object.defineProperty(exports, "__esModule", { value: true });
var apollo_server_1 = require("apollo-server");
var typeDefs = (0, apollo_server_1.gql)(templateObject_1 || (templateObject_1 = __makeTemplateObject(["\n  type Player {\n    id: String!\n    givenName: String!\n    familyName: String!\n    dateOfBirth: String!\n  }\n\n  type Query {\n    player: [Player!]!\n  }\n"], ["\n  type Player {\n    id: String!\n    givenName: String!\n    familyName: String!\n    dateOfBirth: String!\n  }\n\n  type Query {\n    player: [Player!]!\n  }\n"])));
var players = [
    {
        id: 'George_McMuffin1',
        givenName: 'George',
        familyName: 'McMuffin',
        dateOfBirth: '2000-12-01'
    },
];
var resolvers = {
    Query: {
        player: function () { return players; },
    },
};
var server = new apollo_server_1.ApolloServer({
    typeDefs: typeDefs,
    resolvers: resolvers,
    csrfPrevention: true,
});
server.listen().then(function (_a) {
    var url = _a.url;
    console.log("\uD83D\uDE80  Server ready at ".concat(url));
});
var templateObject_1;
