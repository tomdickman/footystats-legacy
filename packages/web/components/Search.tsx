import Link from "next/link"
import React, { ChangeEventHandler, FormEvent, useMemo, useState } from "react"

import styles from "../styles/Search.module.css"

export type SearchItem = {
  searchString: string
  link: string
}

export type SearchProps = {
  items: SearchItem[]
  title?: string
  label?: string
  placeholder?: string
  maxResults?: number
}

export default function Search ({
  items,
  title = 'Search',
  label = '',
  placeholder = '',
  maxResults = 5
}: SearchProps) {
  const [searchResults, setSearchResults] = useState<SearchItem[]>([])

  const handleChange: ChangeEventHandler<HTMLInputElement> = (event: FormEvent<HTMLInputElement>) => {
    const regex = new RegExp(`${event.currentTarget.value}`, 'i')
    const results: SearchItem[] = []
    let i = 0

    while (results.length < maxResults && i < items.length) {
      if (items[i].searchString.match(regex) !== null) {
        results.push(items[i])
      }
      i++
    }
    setSearchResults(results)
  }

  return (
    <form>
      <fieldset className={styles.search}>
        <legend>{title}</legend>
        <div>
          <label htmlFor={styles["searchInput"]}>{label}</label>
        </div>
        <div className={styles.inputBox}>
          <span className={styles.inputContainer}>
            <input id={styles["searchInput"]} type="text" placeholder={placeholder} onChange={handleChange} />
          </span>
          <div className={`${styles.dropdown} ${searchResults.length == 0 ? styles.hidden: ''}`}>
            {searchResults.map(searchResult => {
              return (
                <div className={styles.searchResult} key={searchResult.searchString}>
                  <Link className={styles.resultsLink} href={searchResult.link}>{searchResult.searchString}</Link>
                </div>
              )
            })}
          </div>
        </div>
      </fieldset>
    </form>
  )
}
