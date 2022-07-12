import { gql } from "@apollo/client"
import type { NextPage } from "next"
import Head from "next/head"
import client from "../apollo-client"
import Search, { SearchItem } from "../components/Search"
import { Player } from "../models/Player"
import styles from "../styles/Home.module.css"

type HomeProps = {
  playerSearchList: SearchItem[]
}

const Home: NextPage<HomeProps> = ({ playerSearchList }) => {
  return (
    <div className={styles.container}>
      <Head>
        <title>AFL Footy Stats</title>
        <meta name="description" content="An AFL Fantasy statistics site" />
        <link rel="icon" href="/football_icon.ico" />
      </Head>

      <main className={styles.main}>
        <h1>AFL Footy Stats</h1>
        <Search items={playerSearchList} title="Search for player" label="Name:" placeholder="Player Name" />
      </main>

      <footer className={styles.footer}>
        <a
          href="https:tomdickman.com.au"
          target="_blank"
          rel="noopener noreferrer"
        >
          Built by Tom Dickman
        </a>
      </footer>
    </div>
  )
}

export const getServerSideProps = async () => {
  let playerSearchList: SearchItem[] = []

  try {
    const { data } = await client.query({
      query: gql`
        query getPlayerNames {
          players {
            id
            givenname
            familyname
          }
        }
      `
    })
    playerSearchList = data.players.map((player: Player) => {
      return {
        searchString: `${player.givenname} ${player.familyname}`,
        link: `/player/${player.id}`
      }
    })
  } catch(error) {
    console.log(JSON.stringify(error, null, 2))
  }

  return { props: { playerSearchList } }
};

export default Home
