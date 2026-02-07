import { Controller } from "@hotwired/stimulus"
import { FocusTrap } from "concerns/focus_trap"

export default class extends Controller {
  static targets = [
    "modal",
    "audio",
    "playIcon",
    "pauseIcon",
    "playPauseButton",
    "currentTime",
    "totalTime",
    "progress",
    "progressBar",
    "songTitle",
    "artistName",
    "artistLink",
    "searchInput",
    "songList",
  ]

  connect() {
    this.songs = []
    this.currentSongIndex = 0
    this.audioTarget.volume = 0.25
    this.boundHandleEscape = this.handleEscape.bind(this)

    // Set up focus trap
    Object.assign(this, FocusTrap)
    this.setupFocusTrap(this.modalTarget)

    // Load songs
    this.loadSongs()

    // Set up audio event listeners
    this.audioTarget.addEventListener('timeupdate', () => this.updateProgress())
    this.audioTarget.addEventListener('ended', () => this.handleSongEnd())
    this.audioTarget.addEventListener('loadedmetadata', () => this.updateDuration())
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.closeModal()
    }
  }

  async loadSongs() {
    try {
      const response = await fetch('/music_player.json')
      this.songs = await response.json()
      this.renderSongList()
    } catch (error) {
      console.error('Failed to load songs:', error)
    }
  }

  openModal() {
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.body.style.overflow = 'hidden'
    document.addEventListener("keydown", this.boundHandleEscape)
    this.activateFocusTrap()
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
    this.modalTarget.setAttribute("aria-hidden", "true")
    document.body.style.overflow = ''
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  togglePlay() {
    if (!this.audioTarget.src) {
      this.loadSong(this.songs[this.currentSongIndex])
    }

    if (this.audioTarget.paused) {
      this.audioTarget.play()
      this.playIconTarget.classList.add('hidden')
      this.pauseIconTarget.classList.remove('hidden')
      if (this.hasPlayPauseButtonTarget) {
        this.playPauseButtonTarget.setAttribute("aria-label", "Pause")
      }
    } else {
      this.audioTarget.pause()
      this.playIconTarget.classList.remove('hidden')
      this.pauseIconTarget.classList.add('hidden')
      if (this.hasPlayPauseButtonTarget) {
        this.playPauseButtonTarget.setAttribute("aria-label", "Play")
      }
    }
  }

  playNow(event) {
    const songId = parseInt(event.currentTarget.dataset.songId)
    const song = this.songs.find(s => s.id === songId)
    if (song) {
      this.loadAndPlaySong(song)
    }
  }

  nextSong() {
    this.currentSongIndex = (this.currentSongIndex + 1) % this.songs.length
    this.loadAndPlaySong(this.songs[this.currentSongIndex])
  }

  previousSong() {
    this.currentSongIndex = (this.currentSongIndex - 1) % this.songs.length
    this.loadAndPlaySong(this.songs[this.currentSongIndex])
  }

  seek(event) {
    const rect = this.progressBarTarget.getBoundingClientRect()
    const percent = (event.clientX - rect.left) / rect.width
    this.audioTarget.currentTime = percent * this.audioTarget.duration
  }

  seekKeyboard(event) {
    if (!this.audioTarget.duration) return

    const step = this.audioTarget.duration * 0.05 // 5% jumps

    switch (event.key) {
      case "ArrowRight":
        event.preventDefault()
        this.audioTarget.currentTime = Math.min(
          this.audioTarget.currentTime + step,
          this.audioTarget.duration
        )
        break
      case "ArrowLeft":
        event.preventDefault()
        this.audioTarget.currentTime = Math.max(
          this.audioTarget.currentTime - step,
          0
        )
        break
    }
  }

  search() {
    this.renderSongList()
  }

  loadSong(song) {
    this.audioTarget.src = song.file

    this.songTitleTarget.textContent = song.title
    this.artistNameTarget.textContent = song.artist
    this.artistLinkTarget.href = song.credit_url

    this.currentSongIndex = this.songs.findIndex(s => s.id === song.id)
  }

  loadAndPlaySong(song) {
    this.loadSong(song)
    this.playIconTarget.classList.add('hidden')
    this.pauseIconTarget.classList.remove('hidden')
    this.audioTarget.play()
  }

  handleSongEnd() {
    if (!this.isLooping) {
      this.nextSong()
    }
  }

  updateProgress() {
    const current = this.audioTarget.currentTime
    const duration = this.audioTarget.duration

    if (!isNaN(duration)) {
      this.currentTimeTarget.textContent = this.formatTime(current)
      const percent = (current / duration) * 100
      this.progressTarget.style.width = `${percent}%`

      // Update ARIA attributes for accessibility
      this.progressBarTarget.setAttribute("aria-valuenow", Math.round(percent))
      this.progressBarTarget.setAttribute("aria-valuetext",
        `${this.formatTime(current)} of ${this.formatTime(duration)}`)
    }
  }

  updateDuration() {
    if (!isNaN(this.audioTarget.duration)) {
      this.totalTimeTarget.textContent = this.formatTime(this.audioTarget.duration)
    }
  }

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  renderSongList() {
    const searchTerm = this.searchInputTarget.value.toLowerCase()
    const filteredSongs = this.songs.filter(song =>
      song.title.toLowerCase().includes(searchTerm) ||
      song.artist.toLowerCase().includes(searchTerm)
    )

    this.songListTarget.innerHTML = filteredSongs.map(song => `
      <div class="song-item"
            data-song-id="${song.id}"
            data-action="click->music-player#playNow">
        <div class="song-info">
          <div class="song-title">${song.title}</div>
          <div class="song-artist">${song.artist}</div>
        </div>
        <div class="song-duration">${this.formatTime(song.duration)}</div>
      </div>
    `).join('')
  }
}