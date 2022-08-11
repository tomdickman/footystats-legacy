import { ApolloServer } from 'apollo-server'
  
import context from './context';
import resolvers from './resolvers';
import typeDefs from './types';

const server = new ApolloServer({
  typeDefs,
  resolvers,
  context,
  csrfPrevention: true,
});

// The `listen` method launches a web server.
server.listen({ port: 4000 }).then(({ url }) => {
  console.log(`🚀  Server ready at ${url}`);
});
