import { gql } from 'apollo-server'

const typeDefs = gql`
  type Player {
    id: String!
    givenname: String!
    familyname: String!
    birthdate: String!
    roundstats: [RoundStats!]!
  }

  type RoundStats {
    playerid: String!
    game: Int!
    team: String
    opponent: String
    roundnumber: String
    year: Int
    result: String
    jumpernumber: Int
    kicks: Int
    marks: Int
    handballs: Int
    disposals: Int
    goals: Int
    behinds: Int
    hitouts: Int
    tackles: Int
    rebound50s: Int
    inside50s: Int
    clearances: Int
    clangers: Int
    freekicksfor: Int
    freekicksagainst: Int
    brownlowvotes: Int
    contestedpossessions: Int
    uncontestedpossessions: Int
    contestedmarks: Int
    marksinside50: Int
    onepercenters: Int
    bounces: Int
    goalassists: Int
    fantasypoints: Int
    timeongroundpercentage: Int
  }

  type Query {
    player(id: String!): Player
    players: [Player!]!
    roundStats(playerid: String!, game: Int!): RoundStats
    hello: String
  }
`

export default typeDefs
