import type { NextPage } from "next"
import Head from "next/head"
import styles from "../styles/Home.module.css"

type HomeProps = {
  birthdate: string
}

const Home: NextPage<HomeProps> = ({ birthdate }) => {
  return (
    <div className={styles.container}>
      <Head>
        <title>AFL Footy Stats</title>
        <meta name="description" content="An AFL Fantasy statistics site" />
        <link rel="icon" href="/football_icon.ico" />
      </Head>

      <main className={styles.main}>
        <h1>AFL Footy Stats</h1>
        <p>Coming soon...</p>
      </main>

      <footer className={styles.footer}>
        <a
          href="https:tomdickman.com.au"
          target="_blank"
          rel="noopener noreferrer"
        >
          Built by Tom Dickman
        </a>
        <p style={{ "display": "none" }} >Birthdate: {birthdate}</p>
      </footer>
    </div>
  )
}

export const getServerSideProps = async () => {
  const resp = await fetch(`${process.env.API_URL}`, {
    headers: {
      "method": "POST",
      "Content-Type": "application/json",
      "body": JSON.stringify({
        "query": "query($playerId: String!) { player(id: $playerId) { birthdate }}",
        "variables": {
          "playerId": "Andrew_Brayshaw"
        }
      })
    }
  })
  const data = await resp.json()
  const birthdate = data.data.player.birthdate

  return { props: { birthdate } }
};

export default Home
