import { ApolloServer, gql } from 'apollo-server'

type Player = {
  id: string
  givenName: string
  familyName: string
  dateOfBirth: string
}

const typeDefs = gql`
  type Player {
    id: String!
    givenName: String!
    familyName: String!
    dateOfBirth: String!
  }

  type Query {
    player: [Player!]!
  }
`;

const players: Player[] = [
  {
    id: 'George_McMuffin1',
    givenName: 'George',
    familyName: 'McMuffin',
    dateOfBirth: '2000-12-01'
  },
];

const resolvers = {
  Query: {
    player: () => players,
  },
};

const server = new ApolloServer({
  typeDefs,
  resolvers,
  csrfPrevention: true,
});

// The `listen` method launches a web server.
server.listen().then(({ url }) => {
  console.log(`🚀  Server ready at ${url}`);
});
