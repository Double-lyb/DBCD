<script setup>
// ============================================================
// SearchBar.vue — 搜索条（图书馆检索终端风格）
// ============================================================
import { ref, watch } from 'vue'

const props = defineProps({
  placeholder: { type: String, default: '搜索书名、作者或 ISBN ...' },
  showCategory: { type: Boolean, default: false },
  showPriceRange: { type: Boolean, default: false },
  categories: { type: Array, default: () => [] },
  initialKeyword: { type: String, default: '' },
  initialCategory: { type: String, default: '' },
  initialPriceMin: { type: String, default: '' },
  initialPriceMax: { type: String, default: '' },
})

const emit = defineEmits(['search', 'reset'])

const keyword = ref(props.initialKeyword)
const category = ref(props.initialCategory)
const priceMin = ref(props.initialPriceMin)
const priceMax = ref(props.initialPriceMax)

let debounceTimer = null

function onInput() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    emitSearch()
  }, 300)
}

function emitSearch() {
  emit('search', {
    keyword: keyword.value,
    category: category.value,
    price_min: priceMin.value,
    price_max: priceMax.value,
  })
}

function reset() {
  keyword.value = ''
  category.value = ''
  priceMin.value = ''
  priceMax.value = ''
  emit('reset')
}

watch([category, priceMin, priceMax], () => {
  emitSearch()
})
</script>

<template>
  <div class="search-bar">
    <div class="search-bar__main">
      <span class="search-bar__icon">⌕</span>
      <input
        v-model="keyword"
        type="text"
        class="search-bar__input"
        :placeholder="placeholder"
        @input="onInput"
      />
      <button v-if="keyword" class="search-bar__clear" @click="keyword = ''; onInput()">✕</button>
    </div>
    <select v-if="showCategory" v-model="category" class="search-bar__select">
      <option value="">全部分类</option>
      <option v-for="cat in categories" :key="cat" :value="cat">{{ cat }}</option>
    </select>
    <template v-if="showPriceRange">
      <input
        v-model="priceMin"
        type="number"
        class="search-bar__price"
        placeholder="¥最低价"
        min="0"
      />
      <span class="search-bar__price-sep">—</span>
      <input
        v-model="priceMax"
        type="number"
        class="search-bar__price"
        placeholder="¥最高价"
        min="0"
      />
    </template>
  </div>
</template>

<style scoped>
.search-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.search-bar__main {
  position: relative;
  flex: 1;
  min-width: 240px;
}

.search-bar__icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 1.1rem;
  color: var(--color-text-secondary);
}

.search-bar__input {
  width: 100%;
  padding: 10px 40px 10px 40px;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: #FFF;
  color: var(--color-text);
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.search-bar__input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(93, 64, 55, 0.08);
}

.search-bar__clear {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: var(--color-text-secondary);
  cursor: pointer;
  font-size: 0.85rem;
  padding: 4px;
}

.search-bar__select {
  padding: 10px 14px;
  font-family: var(--font-sans);
  font-size: 0.9rem;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: #FFF;
  color: var(--color-text);
  outline: none;
  cursor: pointer;
  min-width: 120px;
}

.search-bar__price {
  width: 100px;
  padding: 10px 12px;
  font-family: var(--font-mono);
  font-size: 0.9rem;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: #FFF;
  color: var(--color-text);
  outline: none;
}

.search-bar__price:focus {
  border-color: var(--color-primary);
}

.search-bar__price-sep {
  color: var(--color-text-secondary);
  font-family: var(--font-serif);
}
</style>
